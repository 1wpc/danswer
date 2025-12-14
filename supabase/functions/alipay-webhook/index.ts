import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"
import AlipaySdk from 'npm:alipay-sdk@3.6.1'

serve(async (req) => {
  try {
    // Alipay sends data as application/x-www-form-urlencoded
    const formData = await req.formData();
    const params: Record<string, string> = {};
    for (const [key, value] of formData.entries()) {
      if (typeof value === 'string') {
        params[key] = value;
      }
    }

    const appId = Deno.env.get('ALIPAY_APP_ID');
    const privateKey = Deno.env.get('ALIPAY_PRIVATE_KEY');
    const alipayPublicKey = Deno.env.get('ALIPAY_PUBLIC_KEY');

    if (!appId || !privateKey || !alipayPublicKey) {
       console.error('Missing Alipay Config');
       return new Response('fail', { status: 500 });
    }

    const alipaySdk = new AlipaySdk({
      appId,
      privateKey,
      alipayPublicKey,
    });

    const isValid = alipaySdk.checkNotifySign(params);
    if (!isValid) {
      console.error('Invalid Signature');
      return new Response('fail', { status: 400 });
    }

    if (params['trade_status'] === 'TRADE_SUCCESS') {
       const passbackParams = params['passback_params'];
       if (passbackParams) {
         try {
            // passback_params is usually URL encoded
            const { userId, priceId } = JSON.parse(decodeURIComponent(passbackParams));
            
            const supabaseAdmin = createClient(
                Deno.env.get('SUPABASE_URL') ?? '',
                Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
            );

            let updates = {};
            if (priceId === 'basic') {
                updates = { subscription_tier: 'basic', usage_limit: 100 };
            } else if (priceId === 'premium') {
                updates = { subscription_tier: 'premium', usage_limit: 500 };
            }

            if (userId && Object.keys(updates).length > 0) {
                await supabaseAdmin.from('profiles').update(updates).eq('id', userId);
            }
         } catch (e) {
             console.error('Error parsing passback_params', e);
         }
       }
    }

    return new Response('success');
  } catch (e) {
    console.error(e);
    return new Response('fail', { status: 500 });
  }
})
