-- Add menu_pdf_url column to cafes table
ALTER TABLE public.cafes 
ADD COLUMN menu_pdf_url TEXT;

-- Add comment to the column
COMMENT ON COLUMN public.cafes.menu_pdf_url IS 'URL to the cafe menu PDF file';

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_cafes_menu_pdf_url ON public.cafes(menu_pdf_url) WHERE menu_pdf_url IS NOT NULL;
