-- Migration 005: Create PostgreSQL function for user signup via invitation
-- This function encapsulates the logic for a new user signing up.

CREATE OR REPLACE FUNCTION public.handle_new_user_signup(
    invitation_token_input TEXT,
    new_user_id UUID,
    display_name_input TEXT,
    phone_input TEXT
)
RETURNS VOID -- No return value needed
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    invitation_record RECORD;
    org_id UUID;
    branch_id_val UUID;
    user_role TEXT;
BEGIN
    -- 1. Find the invitation and lock the row
    SELECT * INTO invitation_record
    FROM public.invitations
    WHERE token = invitation_token_input AND status = 'pending' AND expires_at > now()
    FOR UPDATE;

    -- If no valid pending invitation found, raise an exception
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation token is invalid or has expired.';
    END IF;

    -- 2. Get data from the invitation
    org_id := invitation_record.organization_id;
    branch_id_val := invitation_record.branch_id;
    user_role := invitation_record.role;

    -- 3. Create the user profile
    INSERT INTO public.user_profiles (user_id, organization_id, branch_id, role, display_name, phone)
    VALUES (new_user_id, org_id, branch_id_val, user_role::user_role, display_name_input, phone_input);

    -- 4. Set the custom claims for the new user in auth.users
    -- This is critical for RLS to work correctly from the first login.
    UPDATE auth.users
    SET raw_app_meta_data = raw_app_meta_data || jsonb_build_object(
        'app_role', user_role,
        'organization_id', org_id
    )
    WHERE id = new_user_id;

    -- 5. Update the invitation to be 'accepted'
    UPDATE public.invitations
    SET status = 'accepted'
    WHERE id = invitation_record.id;

END;
$$;

SELECT 'Migration 005 completed successfully.' as result;
