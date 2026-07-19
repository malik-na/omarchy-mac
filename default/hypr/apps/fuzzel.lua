-- Application-specific animation.
-- Mac fork: fuzzel replaces walker as the launcher; disable its layer animation.
hl.layer_rule({ match = { namespace = "fuzzel" }, no_anim = true })
