import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

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
          .select()
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
}
