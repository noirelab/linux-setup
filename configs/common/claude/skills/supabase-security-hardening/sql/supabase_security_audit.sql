-- Supabase security audit (READ ONLY)
-- Execute only against a local or explicitly authorized database.
-- This file does not alter data or configuration.

-- 1. User tables in commonly exposed schemas without RLS.
select
  n.nspname as schema_name,
  c.relname as relation_name,
  case c.relkind
    when 'r' then 'table'
    when 'p' then 'partitioned_table'
    when 'v' then 'view'
    when 'm' then 'materialized_view'
    else c.relkind::text
  end as relation_type,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('public')
  and c.relkind in ('r', 'p')
  and not c.relrowsecurity
order by 1, 2;

-- 2. RLS-enabled tables with no policies.
select
  n.nspname as schema_name,
  c.relname as table_name
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
left join pg_catalog.pg_policy p on p.polrelid = c.oid
where n.nspname in ('public', 'storage')
  and c.relkind in ('r', 'p')
  and c.relrowsecurity
having count(p.oid) = 0
order by 1, 2;

-- 3. Complete policy inventory.
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual as using_expression,
  with_check
from pg_catalog.pg_policies
where schemaname in ('public', 'storage')
order by schemaname, tablename, policyname;

-- 4. Suspicious policies that appear universally permissive.
-- Confirm manually: text matching is only a heuristic.
select
  schemaname,
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
from pg_catalog.pg_policies
where schemaname in ('public', 'storage')
  and (
    regexp_replace(coalesce(qual, ''), '\s', '', 'g') in ('true', '(true)')
    or regexp_replace(coalesce(with_check, ''), '\s', '', 'g') in ('true', '(true)')
  )
order by schemaname, tablename, policyname;

-- 5. Grants to Data API roles on relations.
select
  grantee,
  table_schema,
  table_name,
  privilege_type,
  is_grantable
from information_schema.role_table_grants
where grantee in ('anon', 'authenticated', 'service_role', 'PUBLIC')
  and table_schema not in ('pg_catalog', 'information_schema')
order by grantee, table_schema, table_name, privilege_type;

-- 6. Column-level grants to Data API roles.
select
  grantee,
  table_schema,
  table_name,
  column_name,
  privilege_type
from information_schema.role_column_grants
where grantee in ('anon', 'authenticated', 'service_role', 'PUBLIC')
order by grantee, table_schema, table_name, column_name, privilege_type;

-- 7. SECURITY DEFINER functions and their configuration.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_catalog.pg_get_function_identity_arguments(p.oid) as arguments,
  pg_catalog.pg_get_userbyid(p.proowner) as owner,
  p.prosecdef as security_definer,
  p.proconfig as function_config,
  pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE') as anon_can_execute,
  pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_can_execute,
  pg_catalog.has_function_privilege('public', p.oid, 'EXECUTE') as public_can_execute
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog', 'information_schema')
  and p.prosecdef
order by 1, 2, 3;

-- 8. Functions with mutable/default search_path.
-- Review all results, especially SECURITY DEFINER functions.
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_catalog.pg_get_function_identity_arguments(p.oid) as arguments,
  p.prosecdef as security_definer,
  p.proconfig
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog', 'information_schema')
  and (
    p.proconfig is null
    or not exists (
      select 1
      from unnest(p.proconfig) cfg
      where cfg like 'search_path=%'
    )
  )
order by p.prosecdef desc, 1, 2, 3;

-- 9. Views and materialized views in commonly exposed schemas.
select
  n.nspname as schema_name,
  c.relname as view_name,
  case c.relkind when 'v' then 'view' when 'm' then 'materialized_view' end as view_type,
  c.reloptions,
  pg_catalog.pg_get_userbyid(c.relowner) as owner
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('public')
  and c.relkind in ('v', 'm')
order by 1, 2;

-- 10. Public Storage buckets.
select
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
from storage.buckets
order by public desc, name;

-- 11. Storage policies specifically.
select
  schemaname,
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
from pg_catalog.pg_policies
where schemaname = 'storage'
order by tablename, policyname;

-- 12. Extensions installed in public schema.
select
  e.extname,
  n.nspname as schema_name,
  e.extversion
from pg_catalog.pg_extension e
join pg_catalog.pg_namespace n on n.oid = e.extnamespace
where n.nspname = 'public'
order by e.extname;

-- 13. Tables containing column names that may be sensitive.
-- Heuristic only; inspect grants and RLS before drawing conclusions.
select
  table_schema,
  table_name,
  string_agg(column_name, ', ' order by ordinal_position) as potentially_sensitive_columns
from information_schema.columns
where table_schema not in ('pg_catalog', 'information_schema')
  and column_name ~* '(password|secret|token|api.?key|ssn|cpf|credit|card|bank|salary|medical|health|private|refresh)'
group by table_schema, table_name
order by table_schema, table_name;
