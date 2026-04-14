-- =============================================
-- ESQUEMA DE BASE DE DATOS PARA VEN_APP
-- Configuración de Supabase
-- =============================================

-- =============================================
-- EXTENSIONES NECESARIAS
-- =============================================
-- Habilitar UUID extension para generar IDs automáticos
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- TABLA: users
-- Almacena la información de los usuarios
-- Se vincula con auth.users de Supabase Auth
-- =============================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    names TEXT NOT NULL,
    surnames TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    address TEXT,
    identification_type TEXT, -- V, E, P (Venezolano, Extranjero, Pasaporte)
    identification_number TEXT,
    documents JSONB, -- Almacena URLs de imágenes: {imageSelfie, imageDocument, imageSelfieWithDocument}
    blocked BOOLEAN DEFAULT FALSE,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- TABLA: rides
-- Almacena la información de los viajes
-- =============================================
CREATE TABLE IF NOT EXISTS public.rides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    firebase_ride_id TEXT, -- Referencia al ride de Firebase (para compatibilidad)
    origin_address TEXT NOT NULL,
    destination_address TEXT NOT NULL,
    origin_latitude DECIMAL(10, 8),
    origin_longitude DECIMAL(11, 8),
    destination_latitude DECIMAL(10, 8),
    destination_longitude DECIMAL(11, 8),
    vehicle_type TEXT, -- tipo de vehículo seleccionado
    fare_amount DECIMAL(10, 2), -- monto del viaje
    distance DECIMAL(10, 2), -- distancia en km
    duration INTEGER, -- duración estimada en minutos
    driver_id TEXT, -- ID del conductor asignado (de Firebase)
    status TEXT DEFAULT 'pending', -- pending, accepted, arrived, ontrip, ended, cancelled
    rating INTEGER, -- calificación dada al conductor
    feedback TEXT, -- comentarios sobre el viaje
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- =============================================
-- ÍNDICES PARA MEJORAR EL RENDIMIENTO
-- =============================================
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_rides_user_id ON public.rides(user_id);
CREATE INDEX IF NOT EXISTS idx_rides_status ON public.rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_created_at ON public.rides(created_at);

-- =============================================
-- ROW LEVEL SECURITY (RLS) - POLÍTICAS
-- =============================================

-- Habilitar RLS en las tablas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rides ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios solo pueden ver y modificar su propio perfil
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Política: Los usuarios solo pueden insertar su propio perfil (durante registro)
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Política: Los usuarios solo pueden ver sus propios viajes
CREATE POLICY "Users can view own rides" ON public.rides
    FOR SELECT USING (auth.uid() = user_id);

-- Política: Los usuarios solo pueden crear sus propios viajes
CREATE POLICY "Users can insert own rides" ON public.rides
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política: Los usuarios solo pueden actualizar sus propios viajes
CREATE POLICY "Users can update own rides" ON public.rides
    FOR UPDATE USING (auth.uid() = user_id);

-- =============================================
-- FUNCIONES Y TRIGGERS
-- =============================================

-- Trigger para actualizar automáticamente el campo updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para tabla users
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para tabla rides
DROP TRIGGER IF EXISTS update_rides_updated_at ON public.rides;
CREATE TRIGGER update_rides_updated_at
    BEFORE UPDATE ON public.rides
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- FUNCIÓN: Manejar nuevo usuario registrado
-- Se ejecuta automáticamente cuando un usuario
-- se registra en Supabase Auth
-- =============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (
        id, email, names, surnames, phone, address,
        identification_type, identification_number, blocked, verified
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'names', ''),
        COALESCE(NEW.raw_user_meta_data->>'surnames', ''),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE(NEW.raw_user_meta_data->>'address', ''),
        COALESCE(NEW.raw_user_meta_data->>'identification_type', ''),
        COALESCE(NEW.raw_user_meta_data->>'identification_number', ''),
        FALSE,
        FALSE
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear perfil automáticamente al registrar usuario
-- NOTA: Si prefieres crear el perfil manualmente desde la app, comenta esta parte
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- PERMISOS
-- =============================================

-- Dar permisos al rol anon para autenticación
-- NOTA: Estos permisos son manejados automáticamente por Supabase Auth

-- Dar permisos al rol authenticated
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.rides TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- =============================================
-- CONFIGURACIÓN DE STORAGE
-- =============================================

-- Crear bucket para documentos de usuarios (público para poder mostrar imágenes)
INSERT INTO storage.buckets (id, name, public)
VALUES ('user-documents', 'user-documents', true)
ON CONFLICT (id) DO NOTHING;

-- Políticas de storage para el bucket user-documents

-- Permitir a usuarios autenticados subir sus propios documentos
CREATE POLICY "Users can upload own documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'user-documents' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Permitir a usuarios autenticados ver sus propios documentos
CREATE POLICY "Users can view own documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'user-documents' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Permitir a usuarios autenticados actualizar sus propios documentos
CREATE POLICY "Users can update own documents" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'user-documents' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Permitir a usuarios autenticados eliminar sus propios documentos
CREATE POLICY "Users can delete own documents" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'user-documents' AND
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- =============================================
-- DATOS DE PRUEBA (opcional)
-- =============================================
-- Descomenta estas líneas si deseas insertar datos de prueba

-- INSERT INTO public.users (id, names, surnames, email, phone, address, blocked, verified)
-- VALUES (
--     'uuid-de-prueba',
--     'Juan',
--     'Pérez',
--     'juan@ejemplo.com',
--     '+58000000000',
--     'Calle Principal #123',
--     false,
--     true
-- );

-- INSERT INTO public.rides (user_id, origin_address, destination_address, vehicle_type, fare_amount, status)
-- VALUES (
--     'uuid-de-prueba',
--     'Calle Principal #123',
--     'Centro Comercial',
--     'Sedan',
--     25.50,
--     'completed'
-- );
