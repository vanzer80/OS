-- Fix payments table status default and existing data
-- Update existing payments with 'paid' status to 'completed'
UPDATE public.payments SET status = 'completed' WHERE status = 'paid';

-- Update the default value for new payments
ALTER TABLE public.payments ALTER COLUMN status SET DEFAULT 'completed';