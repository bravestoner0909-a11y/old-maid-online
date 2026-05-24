# OLD MAID Online MVP

This is a zero-build static web app for Vercel + Supabase.

## Files

- `index.html`: the whole web app
- `config.js`: Supabase URL and anon key
- `supabase.sql`: database tables, realtime publication, and public MVP grants

## Fast setup

1. Create a Supabase project.
2. Open Supabase → SQL Editor → New query.
3. Paste all contents of `supabase.sql` and run it.
4. Open Supabase → Project Settings → API.
5. Copy Project URL and anon public key.
6. Put them in `config.js`.
7. Upload all files to a GitHub repository.
8. Import the repository into Vercel.
9. Deploy.

## Important

This is an MVP speed version. It works as a realtime web game, but the core card logic is still client-side.
After the MVP works, move card actions into Supabase Edge Functions and enable RLS policies.
