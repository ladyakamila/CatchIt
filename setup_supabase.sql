-- ============================================================
-- SETUP TABLES & RLS UNTUK CATCHIT APP
-- Jalankan di: Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. Drop trigger lama (jika ada) agar tidak konflik
drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists on_new_user on auth.users;
drop function if exists public.handle_new_user() cascade;

-- 2. Buat tabel profiles (jika belum ada)
create table if not exists public.profiles (
  id uuid not null primary key,
  full_name text,
  phone_number text,
  avatar_url text,
  role text default 'user',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint profiles_id_fkey foreign key (id) references auth.users (id) on delete cascade
);

-- 3. Aktifkan RLS
alter table public.profiles enable row level security;

-- 4. Drop policy lama biar tidak duplikat, lalu buat ulang
drop policy if exists "Public profiles are viewable by everyone." on public.profiles;
drop policy if exists "Users can insert own profile." on public.profiles;
drop policy if exists "Users can update own profile." on public.profiles;

-- Siapapun yang sudah login bisa lihat profil
create policy "Public profiles are viewable by everyone."
  on public.profiles for select using (true);

-- User hanya bisa insert profilnya sendiri
create policy "Users can insert own profile."
  on public.profiles for insert with check (auth.uid() = id);

-- User hanya bisa update profilnya sendiri
create policy "Users can update own profile."
  on public.profiles for update using (auth.uid() = id);
