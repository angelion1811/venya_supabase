import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/fare_hour_multiplier_model.dart';
import '../models/vehicle_type_model.dart';

/// Servicio de Supabase que reemplaza las llamadas al backend personalizado
/// Maneja autenticación, base de datos y storage
class SupabaseService {
  // Singleton pattern
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Getter para el cliente de Supabase
  static SupabaseClient get client => Supabase.instance.client;

  // ========== AUTHENTICATION ==========

  /// Obtiene el usuario actual autenticado
  static User? get currentUser => client.auth.currentUser;

  /// Obtiene la sesión actual
  static Session? get currentSession => client.auth.currentSession;

  /// Obtiene el token de acceso actual
  static String? get accessToken => client.auth.currentSession?.accessToken;

  /// Registra un nuevo usuario en Supabase Auth y crea el perfil en la tabla users
  /// Retorna un mapa con el resultado de la operación
  static Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData) async {
    try {
      log(userData.toString());
      final email = userData['email'] as String;
      final password = userData['password'] as String;

      // 1. Registrar usuario en Supabase Auth
      // Todos los datos se pasan en userData para que el trigger los use
      final AuthResponse authResponse = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'names': userData['names'] ?? '',
          'surnames': userData['surnames'] ?? '',
          'phone': userData['phone'] ?? '',
          'address': userData['address'] ?? '',
          'identification_type': userData['identification_type'] ?? '',
          'identification_number': userData['identification_number'] ?? '',
        },
      );

      if (authResponse.user == null) {
        return <String, dynamic>{
          'success': false,
          'statusCode': 400,
          'errors': <String, dynamic>{'auth': <String>['Error al registrar usuario']},
        };
      }

      // 2. El perfil se crea automáticamente via trigger on_auth_user_created
      // que ejecuta handle_new_user() con todos los datos del metadata
      final userId = authResponse.user!.id;

      // 3. Esperar un momento para que el trigger termine (si es necesario)
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. Obtener los datos del usuario creado
      // Si el trigger no se ha ejecutado, usamos los datos del metadata
      Map<String, dynamic>? userRecord;
      try {
        userRecord = await client
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();
      } catch (e) {
        log('Error al obtener usuario de DB: $e');
      }

      // Si no se encontró en la DB, usar los datos del Auth user
      if (userRecord == null) {
        log('Perfil no encontrado en DB, usando datos de Auth');
        userRecord = {
          'id': userId,
          'email': email,
          'names': userData['names'] ?? '',
          'surnames': userData['surnames'] ?? '',
          'phone': userData['phone'] ?? '',
          'address': userData['address'] ?? '',
          'identification_type': userData['identification_type'] ?? '',
          'identification_number': userData['identification_number'] ?? '',
          'blocked': false,
          'verified': false,
        };
      }

      // Autenticar también en Firebase Auth para acceso a Firebase Storage
      // No esperamos el resultado para no bloquear el registro
      signInToFirebaseAuth(email, password);

      return <String, dynamic>{
        'success': true,
        'statusCode': 200,
        'token': authResponse.session?.accessToken,
        'data': userRecord,
      };
    } on AuthException catch (error) {
      log('AuthException: ${error.message}');
      // Detectar errores de rate limit
      final errorMsg = error.message.toLowerCase();
      if (errorMsg.contains('rate limit') || errorMsg.contains('exceeded')) {
        return <String, dynamic>{
          'success': false,
          'statusCode': 429,
          'errors': <String, dynamic>{
            'auth': <String>['Demasiados intentos. Espera 1 hora o usa otro email.'],
          },
        };
      }
      return <String, dynamic>{
        'success': false,
        'statusCode': 400,
        'errors': <String, dynamic>{'auth': <String>[error.message]},
      };
    } catch (error) {
      log('Error en registerUser: $error');
      return <String, dynamic>{
        'success': false,
        'statusCode': 500,
        'errors': <String, dynamic>{'server': <String>['Error interno del servidor registre $error']},
      };
    }
  }

  /// Inicia sesión de usuario con email y password
  static Future<Map<String, dynamic>> loginUser(Map<String, dynamic> credentials) async {
    try {
      final email = credentials['email'] as String;
      final password = credentials['password'] as String;

      final AuthResponse authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return <String, dynamic>{
          'success': false,
          'statusCode': 404,
          'message': 'Usuario inválido',
        };
      }

      // Obtener datos del usuario desde la tabla users
      final userRecord = await client
          .from('users')
          .select()
          .eq('id', authResponse.user!.id)
          .single();

      // Autenticar también en Firebase Auth para acceso a Firebase Storage
      signInToFirebaseAuth(email, password);

      return <String, dynamic>{
        'success': true,
        'statusCode': 200,
        'token': authResponse.session?.accessToken,
        'data': (userRecord as Map<dynamic, dynamic>).cast<String, dynamic>(),
      };
    } on AuthException catch (error) {
      log('AuthException: ${error.message}');
      return <String, dynamic>{
        'success': false,
        'statusCode': 400,
        'errors': <String, dynamic>{'auth': <String>[error.message]},
      };
    } catch (error) {
      log('Error en loginUser: $error');
      return <String, dynamic>{
        'success': false,
        'statusCode': 500,
        'errors': <String, dynamic>{'server': <String>['Error interno del servidor']},
      };
    }
  }

  /// Actualiza la contraseña del usuario actual
  static Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Envía un correo de recuperación de contraseña
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Verifica el código de recuperación enviado por correo
  static Future<Map<String, dynamic>> verifyRecoveryCode(String email, String code) async {
    try {
      final response = await client.auth.verifyOTP(
        token: code,
        type: OtpType.recovery,
        email: email,
      );
      if (response.session != null) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Código inválido o expirado'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Cierra la sesión del usuario
  static Future<void> logout() async {
    await client.auth.signOut();
    await firebase_auth.FirebaseAuth.instance.signOut();
  }

  /// Inicia sesión en Firebase Auth (para acceder a Firebase Storage)
  /// Esta función permite mantener compatibilidad con Firebase Storage
  /// mientras usamos Supabase Auth como sistema principal
  static Future<void> signInToFirebaseAuth(String email, String password) async {
    try {
      await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      log('Firebase Auth: Usuario autenticado exitosamente');
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Si el usuario no existe en Firebase, crearlo
      if (e.code == 'user-not-found') {
        try {
          await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          log('Firebase Auth: Usuario creado y autenticado');
        } catch (createError) {
          log('Error al crear usuario en Firebase: $createError');
        }
      } else {
        log('Error al autenticar en Firebase: ${e.message}');
      }
    } catch (e) {
      log('Error inesperado en Firebase Auth: $e');
    }
  }

  // ========== USER PROFILE ==========

  /// Obtiene el perfil del usuario autenticado
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        return <String, dynamic>{
          'success': false,
          'statusCode': 401,
          'message': 'No autorizado',
        };
      }

      final userRecord = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return <String, dynamic>{
        'success': true,
        'statusCode': 200,
        'data': (userRecord as Map<dynamic, dynamic>).cast<String, dynamic>(),
      };
    } catch (error) {
      log('Error en getProfile: $error');
      return <String, dynamic>{
        'success': false,
        'statusCode': 500,
        'errors': <String, dynamic>{'server': <String>['Error al obtener perfil']},
      };
    }
  }

  /// Actualiza los datos del perfil del usuario
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        return <String, dynamic>{
          'success': false,
          'statusCode': 401,
          'message': 'No autorizado',
        };
      }

      await client
          .from('users')
          .update(data)
          .eq('id', userId);

      return <String, dynamic>{
        'success': true,
        'statusCode': 200,
      };
    } catch (error) {
      log('Error en updateProfile: $error');
      return <String, dynamic>{
        'success': false,
        'statusCode': 500,
        'errors': <String, dynamic>{'server': <String>['Error al actualizar perfil']},
      };
    }
  }

  /// Agrega documentos de identificación del usuario
  static Future<Map<String, dynamic>> addUserDocuments(Map<String, dynamic> documents) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        return <String, dynamic>{
          'success': false,
          'statusCode': 401,
          'message': 'No autorizado',
        };
      }

      await client
          .from('users')
          .update({
            'documents': documents,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return <String, dynamic>{
        'success': true,
        'statusCode': 201,
        'message': 'Documentos guardados exitosamente',
      };
    } catch (error) {
      log('Error en addUserDocuments: $error');
      return <String, dynamic>{
        'success': false,
        'statusCode': 400,
        'errors': <String, dynamic>{'documents': <String>['Error al guardar documentos']},
      };
    }
  }

  // ========== RIDES ==========

  /// Guarda información de un viaje en la base de datos
  static Future<Map<String, dynamic>> saveRide(Map<String, dynamic> rideData) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        return <String, dynamic>{
          'success': false,
          'statusCode': 401,
          'message': 'No autorizado',
        };
      }

      // Extraer coordenadas de los mapas anidados origin/destination
      final origin = rideData['origin'] as Map<String, dynamic>?;
      final destination = rideData['destination'] as Map<String, dynamic>?;

      // Preparar datos del viaje
      final rideRecord = <String, dynamic>{
        'user_id': userId,
        'origin_address': rideData['originAddress'],
        'destination_address': rideData['destinationAddress'],
        'origin_latitude': origin?['latitude'],
        'origin_longitude': origin?['longitude'],
        'destination_latitude': destination?['latitude'],
        'destination_longitude': destination?['longitude'],
        'vehicle_type': rideData['vehicleType'],
        'fare_amount': rideData['fareAmount'],
        'distance': rideData['distance'],
        'duration': rideData['duration'],
        'status': rideData['status'] ?? 'pending',
        'created_at': DateTime.now().toIso8601String(),
        // Datos adicionales del usuario
        'user_name': rideData['userName'],
        'user_phone': rideData['userPhone'],
        'package_details': rideData['packageDetails'],
        'water_liters': rideData['waterLiters'],
        // Campos opcionales que pueden venir del ride request de Firebase
        'firebase_ride_id': rideData['_id'],
        'driver_id': rideData['driverId'],
      };

      final response = await client
          .from('rides')
          .insert(rideRecord)
          .select()
          .single();

      return <String, dynamic>{
        'success': true,
        'statusCode': 200,
        'data': (response as Map<dynamic, dynamic>).cast<String, dynamic>(),
      };
    } catch (error) {
      log('Error en saveRide: $error');
      return <String, dynamic>{
        'success': false,
        'statusCode': 500,
        'errors': <String, dynamic>{'server': <String>['Error al guardar viaje']},
      };
    }
  }

  /// Verifica si un viaje ya fue guardado en Supabase (historial) utilizando el ID de Firebase
  static Future<bool> isRideSaved(String firebaseRideId) async {
    try {
      final result = await client
          .from('rides')
          .select('id')
          .eq('firebase_ride_id', firebaseRideId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      log('Error en isRideSaved: $e');
      return false;
    }
  }

  /// Verifica si el usuario tiene viajes por calificar (rating es null)
  static Future<List<Map<String, dynamic>>> getUnratedRides() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return [];

      final rides = await client
          .from('rides')
          .select('*, drivers(names, surnames, documents)')
          .eq('user_id', userId)
          .filter('rating', 'is', 'null')  // Buscar viajes SIN calificación (rating = NULL)
          .order('created_at', ascending: false);

      return (rides as List<dynamic>)
          .map((ride) => (ride as Map<dynamic, dynamic>).cast<String, dynamic>())
          .toList();
    } catch (error) {
      log('Error en getUnratedRides: $error');
      return [];
    }
  }

  /// Obtiene un viaje específico de Supabase por su ID (UUID) para calificar
  /// Busca por el campo 'id' (UUID de Supabase) o por 'firebase_ride_id'
  static Future<Map<String, dynamic>?> getRideBySupabaseId(String rideId) async {
    try {
      final result = await client
          .from('rides')
          .select('*, drivers(names, surnames)')
          .or('id.eq.$rideId,firebase_ride_id.eq.$rideId')
          .maybeSingle();

      return result != null ? (result as Map<dynamic, dynamic>).cast<String, dynamic>() : null;
    } catch (error) {
      log('Error en getRideById: $error');
      return null;
    }
  }

  /// Actualiza el rating de un viaje existente por su ID de Supabase (UUID)
  static Future<Map<String, dynamic>> updateRideRating(String supabaseRideId, double rating) async {
    try {
      log("Actualizando calificación de viaje $supabaseRideId con rating: $rating");

      final response = await client
          .from('rides')
          .update({
            'rating': rating.toInt(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', supabaseRideId)
          .select()
          .single();

      return {
        'success': true,
        'statusCode': 200,
        'data': (response as Map<dynamic, dynamic>).cast<String, dynamic>(),
      };
    } catch (error) {
      log('Error en updateRideRating: $error');
      return {
        'success': false,
        'statusCode': 500,
        'message': 'Error al actualizar calificación',
      };
    }
  }

  /// Obtiene el historial de viajes del usuario
  static Future<Map<String, dynamic>> getRidesHistory() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        return <String, dynamic>{
          'success': false,
          'statusCode': 401,
          'message': 'No autorizado',
        };
      }

      final rides = await client
          .from('rides')
          .select('*, drivers(names, surnames, documents)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return <String, dynamic>{
        'success': true,
        'statusCode': 200,
        'data': (rides as List<dynamic>)
            .map((ride) => (ride as Map<dynamic, dynamic>).cast<String, dynamic>())
            .toList(),
      };
    } catch (error) {
      log('Error en getRidesHistory: $error');
      return <String, dynamic>{
        'success': false,
        'statusCode': 500,
        'errors': <String, dynamic>{'server': <String>['Error al obtener historial']},
      };
    }
  }

  /// Califica a un conductor y actualiza el viaje en Supabase
  static Future<Map<String, dynamic>> rateDriver(String driverId, String rideId, double rating) async {
    try {
      // 1. Actualizar la calificación en el registro del viaje
      await client
          .from('rides')
          .update({'rating': rating.toInt()})
          .eq('firebase_ride_id', rideId); // Usar firebase_ride_id porque es el ID que tiene la app en este momento

      // La actualización del promedio del conductor se debe hacer con un trigger en la BD
      // o desde la app del conductor. La app de pasajeros no tiene permisos para actualizar
      // la tabla de drivers (o ni siquiera existe en su esquema).

      return {'success': true};
    } catch (error) {
      log('Error en rateDriver: $error');
      Fluttertoast.showToast(
        msg: 'Error al calificar conductor: $error',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return {'success': false, 'message': error.toString()};
    }
  }

  /// Obtiene el fare_amount de un viaje en Supabase a partir del firebase_ride_id
  /// Retorna null si no se encontró el viaje o si el campo está vacío
  static Future<double?> getFareAmountByFirebaseId(String firebaseRideId) async {
    try {
      final result = await client
          .from('rides')
          .select('fare_amount')
          .eq('firebase_ride_id', firebaseRideId)
          .maybeSingle();

      print("result: $result");
      print("fare_amount: ${result?['fare_amount']}");

      if (result == null || result['fare_amount'] == null) return null;
      return (result['fare_amount'] as num).toDouble();
    } catch (e) {
      log('Error en getFareAmountByFirebaseId: $e');
      Fluttertoast.showToast(
        msg: 'Error al obtener el monto del viaje',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return null;
    }
  }

  // ========== VEHICLE TYPES ==========

  static Future<List<VehicleType>> getActiveVehicleTypes() async {
    try {
      final response = await client
          .from('vehicle_types')
          .select('*')
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List<dynamic>)
          .map((e) => VehicleType.fromJson((e as Map<dynamic, dynamic>).cast<String, dynamic>()))
          .toList();
    } catch (error) {
      log('Error en getActiveVehicleTypes: $error');
      return [];
    }
  }

  /// Obtiene los multiplicadores horarios activos para todos los tipos de vehículo que aplican al intervalo de hora actual
  static Future<List<FareHourMultiplier>> getActiveFareHourMultipliers() async {
    try {
      final response = await client
          .from('fare_hour_multipliers')
          .select('*')
          .eq('is_active', true);

      final allMultipliers = (response as List<dynamic>)
          .map((e) => FareHourMultiplier.fromJson((e as Map<dynamic, dynamic>).cast<String, dynamic>()))
          .toList();

      return allMultipliers.where((multiplier) => multiplier.isCurrentTimeInRange()).toList();
    } catch (error) {
      log('Error en getActiveFareHourMultipliers: $error');
      return [];
    }
  }

  // ========== FUTURE RIDES ==========

  /// Obtiene todos los viajes futuros activos
  static Future<List<Map<String, dynamic>>> getAllFutureRides() async {
    try {
      final userId = currentUser?.id;
      final result = await client
          .from('future_rides')
          .select('*, drivers(names, surnames, phone, car_details), future_ride_passengers(user_id, seats_booked, status)')
          .eq('status', 'active')
          .gte('ride_date', DateTime.now().toIso8601String())
          .order('ride_date', ascending: true);

      // Procesar datos de pasajeros
      final rides = List<Map<String, dynamic>>.from(result);
      for (var ride in rides) {
        final passengers = ride['future_ride_passengers'] as List;
        
        int booked = 0;
        bool isUserPassenger = false;
        int userBookedSeats = 0;

        for (var p in passengers) {
          if (p['status'] == 'confirmed') {
            booked += (p['seats_booked'] as int);
            if (userId != null && p['user_id'] == userId) {
              isUserPassenger = true;
              userBookedSeats = p['seats_booked'] as int;
            }
          }
        }
        ride['booked_seats'] = booked;
        ride['is_user_passenger'] = isUserPassenger;
        ride['user_booked_seats'] = userBookedSeats;
      }

      return rides;
    } catch (e) {
      log('Error en getAllFutureRides: $e');
      return [];
    }
  }

  /// Reserva un puesto en un viaje futuro
  static Future<Map<String, dynamic>> bookFutureRideSeat(String rideId, int seats) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'No autorizado'};

      // Verificar si ya existe una reserva previa (incluso cancelada)
      final existing = await client
          .from('future_ride_passengers')
          .select()
          .eq('future_ride_id', rideId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Si ya existía, actualizamos el estado y la cantidad de puestos
        final result = await client
            .from('future_ride_passengers')
            .update({
              'seats_booked': seats,
              'status': 'confirmed',
            })
            .eq('id', existing['id'])
            .select()
            .single();
        return {'success': true, 'data': result};
      } else {
        // Si es la primera vez, insertamos el nuevo registro
        final result = await client.from('future_ride_passengers').insert({
          'future_ride_id': rideId,
          'user_id': userId,
          'seats_booked': seats,
          'status': 'confirmed',
        }).select().single();
        return {'success': true, 'data': result};
      }
    } catch (e) {
      log('Error en bookFutureRideSeat: $e');
      return {'success': false, 'message': 'Error al procesar la reserva'};
    }
  }

  /// Cancela una reserva en un viaje futuro
  static Future<Map<String, dynamic>> cancelFutureRideReservation(String rideId) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return {'success': false, 'message': 'No autorizado'};

      await client
          .from('future_ride_passengers')
          .update({
            'status': 'cancelled',
            'seats_booked': 0,
          })
          .eq('future_ride_id', rideId)
          .eq('user_id', userId);

      return {'success': true};
    } catch (e) {
      log('Error en cancelFutureRideReservation: $e');
      return {'success': false, 'message': 'Error al cancelar la reserva'};
    }
  }

  // ========== UTILIDADES ==========

  /// Verifica si hay una sesión activa
  static bool get isAuthenticated => currentUser != null;

  /// Escucha cambios en el estado de autenticación
  static Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;

  /// Convierte un registro de Supabase a UserModel
  static UserModel userRecordToModel(Map<String, dynamic> record) {
    return UserModel(
      id: record['id'],
      names: record['names'],
      surnames: record['surnames'],
      phone: record['phone'],
      email: record['email'],
      address: record['address'],
      documents: record['documents'],
      blocked: record['blocked'],
      verified: record['verified'],
    );
  }

  // ========== STORAGE ==========

  /// Sube un archivo al bucket de Supabase Storage
  /// Retorna la URL pública del archivo subido
  static Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String bucketName,
    required String folderPath,
    required String fileName,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) {
        return <String, dynamic>{
          'success': false,
          'statusCode': 401,
          'message': 'Usuario no autenticado',
        };
      }

      // Crear la ruta completa: user-id/folder/filename
      final fullPath = '$userId/$folderPath/$fileName';

      // Subir el archivo
      await client.storage.from(bucketName).upload(
            fullPath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Obtener la URL pública
      final String publicUrl = client.storage.from(bucketName).getPublicUrl(fullPath);

      return <String, dynamic>{
        'success': true,
        'statusCode': 200,
        'url': publicUrl,
        'path': fullPath,
      };
    } on StorageException catch (error) {
      log('StorageException: ${error.message}');
      return <String, dynamic>{
        'success': false,
        'statusCode': error.statusCode ?? 400,
        'message': error.message,
      };
    } catch (error) {
      log('Error en uploadFile: $error');
      return <String, dynamic>{
        'success': false,
        'statusCode': 500,
        'message': 'Error al subir archivo: $error',
      };
    }
  }

  /// Elimina un archivo del bucket de Supabase Storage
  static Future<Map<String, dynamic>> deleteFile({
    required String bucketName,
    required String filePath,
  }) async {
    try {
      await client.storage.from(bucketName).remove([filePath]);

      return <String, dynamic>{
        'success': true,
        'statusCode': 200,
        'message': 'Archivo eliminado exitosamente',
      };
    } on StorageException catch (error) {
      log('StorageException: ${error.message}');
      return <String, dynamic>{
        'success': false,
        'statusCode': error.statusCode ?? 400,
        'message': error.message,
      };
    } catch (error) {
      log('Error en deleteFile: $error');
      return <String, dynamic>{
        'success': false,
        'statusCode': 500,
        'message': 'Error al eliminar archivo: $error',
      };
    }
  }

  // ========== FUNCTIONS ==========

  /// Invoca una función de Supabase (Edge Function)
  static Future<FunctionResponse> invokeFunction(String functionName, {Map<String, dynamic>? body}) async {
    try {
      final response = await client.functions.invoke(
        functionName,
        body: body,
      );
      return response;
    } catch (error) {
      log('Error invoking function $functionName: $error');
      rethrow;
    }
  }
}
