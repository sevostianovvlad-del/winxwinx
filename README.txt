English Alfea — secure Supabase developer mode

1. Upload index.html to the root of the GitHub Pages repository.
2. Supabase project URL is already configured in the HTML.
3. The browser uses only the publishable key. Do NOT add a secret/service_role key.
4. Developer mode is shown only after Supabase login AND a user_roles row with role admin or developer.
5. To open the login form, visit the site with ?admin=1 once.
6. The old ?dev=1 / #dev method no longer grants developer access.

Required database table:
public.user_roles(user_id uuid primary key references auth.users(id), role text check(role in ('admin','developer','student')))
with a SELECT RLS policy allowing a user to read only their own row.
