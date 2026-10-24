import { createClient } from '@supabase/supabase-js';
const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
// Publishable keys are the current Supabase standard. Keep the legacy anon
// variable as a fallback so existing deployments continue to work.
const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
export const supabase=url&&key?createClient(url,key):null;
