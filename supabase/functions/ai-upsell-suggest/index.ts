import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
    if (!GEMINI_API_KEY) {
      throw new Error("GEMINI_API_KEY is not set in environment variables");
    }

    const { cartItems, menuItems } = await req.json();

    if (!cartItems || cartItems.length === 0) {
      return new Response(JSON.stringify({ suggestion: null }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const cartContext = cartItems.map((i: any) => `${i.quantity}x ${i.productName}`).join(", ");
    const menuContext = menuItems.map((i: any) => `${i.id}: ${i.name} (₹${i.basePrice})`).join("\n");

    const prompt = `
You are an expert restaurant manager AI.
The customer currently has these items in their cart:
${cartContext}

Here is the available menu:
${menuContext}

Pick EXACTLY ONE highly complementary item from the menu to suggest as an upsell. 
Do not suggest an item they already have in their cart.
Return a raw JSON object (without markdown formatting) with this exact structure:
{
  "productId": "id_of_the_suggested_item",
  "reason": "A short, persuasive reason why they should add this (e.g. 'Perfect pairing with your burger', 'Cool down with a refreshing drink')"
}
If no logical upsell exists, return { "productId": null, "reason": null }.
`;

    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.7,
          responseMimeType: "application/json",
        }
      })
    });

    if (!response.ok) {
      throw new Error(`Gemini API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    let resultText = data.candidates?.[0]?.content?.parts?.[0]?.text;
    
    if (!resultText) {
      throw new Error("Empty response from Gemini");
    }

    // Clean markdown code blocks if gemini returned them despite responseMimeType
    resultText = resultText.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
    const suggestion = JSON.parse(resultText);

    return new Response(JSON.stringify(suggestion), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("AI Upsell error:", error);
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Internal Server Error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
