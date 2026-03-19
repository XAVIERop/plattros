// Secure PrintNode Edge Function
// All PrintNode API keys are stored server-side only
// This prevents API key exposure in frontend code

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// PrintNode API keys stored in Supabase Edge Function secrets
// Access via: Deno.env.get('PRINTNODE_API_KEY_CHATKARA')
const PRINTNODE_BASE_URL = 'https://api.printnode.com';
const DEFAULT_ALLOWED_ORIGINS = ['https://mujfoodclub.in', 'https://pos.mujfoodclub.in', 'http://localhost:8080', 'http://localhost:8090', 'http://localhost:8091', 'http://localhost:5173'];
const ALLOWED_ORIGINS = (Deno.env.get('ALLOWED_ORIGINS') || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

function resolveCorsOrigin(req: Request): string {
  const origin = req.headers.get('origin') || '';
  const allowlist = ALLOWED_ORIGINS.length > 0 ? ALLOWED_ORIGINS : DEFAULT_ALLOWED_ORIGINS;
  return origin && allowlist.includes(origin) ? origin : allowlist[0];
}

interface PrintNodeRequest {
  action: 'print_receipt' | 'print_kot' | 'check_printer' | 'list_printers';
  cafe_id?: string;
  cafe_name?: string;
  receipt_data?: any;
  kot_data?: any;
  printer_id?: number;
}

// Get API key for specific cafe
function getCafeApiKey(cafeName: string): string | null {
  const normalizedName = cafeName.toLowerCase().trim();
  
  // Map cafe names to environment variable names
  const keyMap: Record<string, string> = {
    'chatkara': 'PRINTNODE_API_KEY_CHATKARA',
    'punjabi tadka': 'PRINTNODE_API_KEY_PUNJABI_TADKA',
    'munch box': 'PRINTNODE_API_KEY_MUNCHBOX',
    'grabit': 'PRINTNODE_API_KEY_GRABIT',
    '24 seven mart': 'PRINTNODE_API_KEY_24_SEVEN_MART',
    'banna\'s chowki': 'PRINTNODE_API_KEY_BANNAS_CHOWKI',
    'bannas chowki': 'PRINTNODE_API_KEY_BANNAS_CHOWKI',
    'amor': 'PRINTNODE_API_KEY_AMOR',
    'stardom': 'PRINTNODE_API_KEY_STARDOM',
    'pizza bakers': 'PRINTNODE_API_KEY_PIZZA_BAKERS',
    'cookhouse': 'PRINTNODE_API_KEY_COOKHOUSE',
    'food court': 'PRINTNODE_API_KEY_FOODCOURT',
  };

  // Find matching cafe
  for (const [key, envVar] of Object.entries(keyMap)) {
    if (normalizedName.includes(key)) {
      const apiKey = Deno.env.get(envVar);
      if (apiKey) {
        console.log(`✅ Using API key for: ${key}`);
        return apiKey;
      }
    }
  }

  // Fallback to default key
  const defaultKey = Deno.env.get('PRINTNODE_API_KEY_DEFAULT');
  if (defaultKey) {
    console.log('⚠️ Using default API key');
    return defaultKey;
  }

  console.error('❌ No PrintNode API key found');
  return null;
}

// Rate limiting: Track requests per IP
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT_MAX = 60; // 60 requests per minute
const RATE_LIMIT_WINDOW = 60000; // 1 minute

function checkRateLimit(ip: string): boolean {
  const now = Date.now();
  const record = rateLimitMap.get(ip);

  if (!record || now > record.resetAt) {
    rateLimitMap.set(ip, { count: 1, resetAt: now + RATE_LIMIT_WINDOW });
    return true;
  }

  if (record.count >= RATE_LIMIT_MAX) {
    return false;
  }

  record.count++;
  return true;
}

// Make authenticated request to PrintNode API
async function printNodeRequest(
  apiKey: string,
  endpoint: string,
  method: string = 'GET',
  body?: any
): Promise<Response> {
  const url = `${PRINTNODE_BASE_URL}${endpoint}`;
  const auth = btoa(`${apiKey}:`);

  const response = await fetch(url, {
    method,
    headers: {
      'Authorization': `Basic ${auth}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  return response;
}

serve(async (req) => {
  const corsOrigin = resolveCorsOrigin(req);
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': corsOrigin,
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  try {
    // Rate limiting
    const clientIp = req.headers.get('x-forwarded-for')?.split(',')[0] || 
                     req.headers.get('x-real-ip') || 
                     'unknown';
    
    if (!checkRateLimit(clientIp)) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Rate limit exceeded. Please try again later.' 
        }),
        {
          status: 429,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': corsOrigin,
            'Retry-After': '60',
          },
        }
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const authHeader = req.headers.get('Authorization');
    const jwt = authHeader?.replace(/^Bearer\s+/i, '').trim();
    if (!jwt) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized: missing bearer token' }),
        {
          status: 401,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': corsOrigin,
          },
        }
      );
    }

    const { data: authData, error: authError } = await supabase.auth.getUser(jwt);
    const caller = authData?.user;
    if (authError || !caller) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized: invalid token' }),
        {
          status: 401,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': corsOrigin,
          },
        }
      );
    }

    const { data: callerProfile } = await supabase
      .from('profiles')
      .select('id, user_type, cafe_id')
      .eq('id', caller.id)
      .maybeSingle();

    const callerRole = callerProfile?.user_type || 'unknown';
    const isSuperAdmin = callerRole === 'super_admin';
    if (!['super_admin', 'cafe_owner', 'cafe_staff'].includes(callerRole)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Forbidden: invalid role for printing' }),
        {
          status: 403,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': corsOrigin,
          },
        }
      );
    }

    // Parse request
    const { action, cafe_id, cafe_name, receipt_data, kot_data, printer_id } = 
      await req.json() as PrintNodeRequest;

    if (!action) {
      return new Response(
        JSON.stringify({ success: false, error: 'Action is required' }),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': corsOrigin,
          },
        }
      );
    }

    // Resolve caller-allowed cafe scope.
    let authorizedCafeId = cafe_id || null;
    if (!isSuperAdmin) {
      const isOwnerForCafe = callerRole === 'cafe_owner' && !!callerProfile?.cafe_id;
      if (!authorizedCafeId && isOwnerForCafe) {
        authorizedCafeId = callerProfile!.cafe_id;
      }
      if (!authorizedCafeId) {
        const { data: staffRow } = await supabase
          .from('cafe_staff')
          .select('cafe_id')
          .eq('user_id', caller.id)
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();
        authorizedCafeId = staffRow?.cafe_id || null;
      }
      if (!authorizedCafeId) {
        return new Response(
          JSON.stringify({ success: false, error: 'Forbidden: no cafe access found for caller' }),
          {
            status: 403,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': corsOrigin,
            },
          }
        );
      }
      if (callerRole === 'cafe_owner' && callerProfile?.cafe_id && callerProfile.cafe_id !== authorizedCafeId) {
        return new Response(
          JSON.stringify({ success: false, error: 'Forbidden: cafe ownership mismatch' }),
          {
            status: 403,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': corsOrigin,
            },
          }
        );
      }
      if (callerRole === 'cafe_staff') {
        const { data: staffCheck } = await supabase
          .from('cafe_staff')
          .select('id')
          .eq('user_id', caller.id)
          .eq('cafe_id', authorizedCafeId)
          .eq('is_active', true)
          .maybeSingle();
        if (!staffCheck) {
          return new Response(
            JSON.stringify({ success: false, error: 'Forbidden: cafe staff membership mismatch' }),
            {
              status: 403,
              headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': corsOrigin,
              },
            }
          );
        }
      }
    }

    // Get cafe name from database if not provided (or to enforce caller scope).
    let finalCafeName = cafe_name;
    const cafeIdToUse = authorizedCafeId || cafe_id;
    if (!finalCafeName || cafeIdToUse) {
      const { data: cafe } = await supabase
        .from('cafes')
        .select('id, name')
        .eq('id', cafeIdToUse)
        .maybeSingle();

      if (!cafe?.name && !isSuperAdmin) {
        return new Response(
          JSON.stringify({ success: false, error: 'Forbidden: invalid or inaccessible cafe' }),
          {
            status: 403,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': corsOrigin,
            },
          }
        );
      }
      if (cafe?.name) {
        finalCafeName = cafe.name;
      }
    }

    if (!finalCafeName) {
      return new Response(
        JSON.stringify({ success: false, error: 'Cafe name or ID is required' }),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': corsOrigin,
          },
        }
      );
    }

    // Get API key for cafe
    const apiKey = getCafeApiKey(finalCafeName);
    if (!apiKey) {
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: `PrintNode API key not configured for cafe: ${finalCafeName}` 
        }),
        {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': corsOrigin,
          },
        }
      );
    }

    // Handle different actions
    switch (action) {
      case 'check_printer':
        if (!printer_id) {
          return new Response(
            JSON.stringify({ success: false, error: 'Printer ID is required' }),
            { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': corsOrigin } }
          );
        }
        const printerResponse = await printNodeRequest(apiKey, `/printers/${printer_id}`);
        const printerData = await printerResponse.json();
        return new Response(
          JSON.stringify({ success: printerResponse.ok, data: printerData }),
          {
            status: printerResponse.status,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': corsOrigin,
            },
          }
        );

      case 'list_printers':
        const listResponse = await printNodeRequest(apiKey, '/printers');
        const listData = await listResponse.json();
        return new Response(
          JSON.stringify({ success: listResponse.ok, data: listData }),
          {
            status: listResponse.status,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': corsOrigin,
            },
          }
        );

      case 'print_receipt':
      case 'print_kot':
        if (!receipt_data && !kot_data) {
          return new Response(
            JSON.stringify({ success: false, error: 'Receipt or KOT data is required' }),
            { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': corsOrigin } }
          );
        }

        // Resolve printer_id from cafe_printer_configs when not provided (e.g. POS queue)
        let resolvedPrinterId = printer_id;
        if (!resolvedPrinterId && cafeIdToUse) {
          const { data: printerConfig } = await supabase
            .from('cafe_printer_configs')
            .select('printnode_printer_id')
            .eq('cafe_id', cafeIdToUse)
            .eq('is_active', true)
            .eq('is_default', true)
            .limit(1)
            .maybeSingle();
          resolvedPrinterId = printerConfig?.printnode_printer_id ?? null;
        }
        if (!resolvedPrinterId) {
          return new Response(
            JSON.stringify({ success: false, error: 'Printer ID is required and no default printer configured for this cafe' }),
            { status: 400, headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': corsOrigin } }
          );
        }

        // Format print data (ESC/POS commands)
        const printData = action === 'print_receipt' ? receipt_data : kot_data;
        const printJob = {
          printerId: resolvedPrinterId,
          contentType: 'raw_base64',
          content: btoa(printData), // Base64 encode
          source: 'Food Club',
        };

        const printResponse = await printNodeRequest(
          apiKey,
          '/printjobs',
          'POST',
          printJob
        );

        const printResult = await printResponse.json();
        return new Response(
          JSON.stringify({ 
            success: printResponse.ok, 
            data: printResult,
            jobId: printResult.id 
          }),
          {
            status: printResponse.status,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': corsOrigin,
            },
          }
        );

      default:
        return new Response(
          JSON.stringify({ success: false, error: `Unknown action: ${action}` }),
          {
            status: 400,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': corsOrigin,
            },
          }
        );
    }

  } catch (error) {
    console.error('❌ PrintNode Edge Function Error:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': corsOrigin,
        },
      }
    );
  }
});

