-- English Alfea: secure admin functions for user management
-- Run this AFTER the user_roles table has already been created.

create or replace function public.admin_set_user_role(target_user_id uuid, new_role text)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  caller_role text;
  target_email text;
begin
  select role into caller_role
  from public.user_roles
  where user_id = auth.uid();

  if caller_role is distinct from 'admin' then
    raise exception 'Только admin может изменять роли';
  end if;

  if new_role not in ('admin','developer','student') then
    raise exception 'Недопустимая роль';
  end if;

  select email into target_email from auth.users where id = target_user_id;
  if target_email is null then
    raise exception 'Пользователь не найден';
  end if;

  insert into public.user_roles(user_id, role)
  values(target_user_id, new_role)
  on conflict(user_id) do update set role = excluded.role;

  return jsonb_build_object('user_id', target_user_id, 'email', target_email, 'role', new_role);
end;
$$;

create or replace function public.admin_list_users()
returns table(user_id uuid, email text, role text, created_at timestamptz)
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  caller_role text;
begin
  select ur.role into caller_role from public.user_roles ur where ur.user_id = auth.uid();
  if caller_role is distinct from 'admin' then
    raise exception 'Только admin может просматривать пользователей';
  end if;

  return query
  select u.id, u.email::text, coalesce(ur.role,'student'), u.created_at
  from auth.users u
  left join public.user_roles ur on ur.user_id = u.id
  order by u.created_at desc;
end;
$$;

revoke execute on function public.admin_set_user_role(uuid,text) from public, anon;
revoke execute on function public.admin_list_users() from public, anon;
grant execute on function public.admin_set_user_role(uuid,text) to authenticated;
grant execute on function public.admin_list_users() to authenticated;
