-- Off-campus cafes: change closing time from 11pm to 10pm
-- Smart automation will use these timing windows

UPDATE public.cafes
SET
  delivery_end_time = '22:00:00',
  dine_in_end_time = '22:00:00',
  takeaway_end_time = '22:00:00',
  updated_at = NOW()
WHERE location_scope = 'off_campus';
