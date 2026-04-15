th.dupes = th.dupes or {}
-- th.dupes.mark_style = ui.Style():fg("#FFFFFF")
-- th.dupes.mark_style = ui.Style():fg("blue")
-- th.dupes.mark_sign = "X"

require("dupes"):setup({
    -- Global settings
    -- save_op = false, -- Default: don't save results to file
    save_op = true,
    auto_confirm = false, -- Default: prompt before deletion

    profiles = {
        -- Interactive mode: recursively scan and display duplicates
        interactive = {
            args = { "-r" },
        },
        -- Apply mode: recursively scan and DELETE duplicates
        apply = {
            args = { "-r", "-N", "-d" },
            save_op = true, -- Save results before deletion
        },
        -- Custom profile example (uncomment to use)
        -- custom = {
        -- 	args = { "-r", "-s", },  -- Your custom jdupes flags
        -- },
    },
})
