-- Create a table for public profiles
create table profiles (
  id uuid references auth.users not null primary key,
  email text,
  subscription_tier text check (subscription_tier in ('free', 'basic', 'premium')) default 'free',
  usage_count integer default 0,
  usage_limit integer default 5, -- Free tier limit
  last_reset timestamptz default now(),
  stripe_customer_id text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Set up Row Level Security (RLS)
alter table profiles enable row level security;

create policy "Public profiles are viewable by everyone." on profiles
  for select using (true);

create policy "Users can insert their own profile." on profiles
  for insert with check (auth.uid() = id);

create policy "Users can update own profile." on profiles
  for update using (auth.uid() = id);

-- Function to handle new user signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, subscription_tier, usage_limit)
  values (new.id, new.email, 'free', 5);
  return new;
end;
$$ language plpgsql security definer;

-- Trigger the function every time a user is created
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Function to increment usage count (to be called by Edge Function or Rpc)
create or replace function increment_usage(user_id uuid)
returns void as $$
begin
  update public.profiles
  set usage_count = usage_count + 1,
      updated_at = now()
  where id = user_id;
end;
$$ language plpgsql security definer;

-- Function to check usage limit
create or replace function check_usage_limit(user_id uuid)
returns boolean as $$
declare
  user_limit integer;
  current_usage integer;
begin
  select usage_limit, usage_count into user_limit, current_usage
  from public.profiles
  where id = user_id;
  
  if current_usage < user_limit then
    return true;
  else
    return false;
  end if;
end;
$$ language plpgsql security definer;
