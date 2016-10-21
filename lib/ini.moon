generate_ini = (data, rec_sec) ->
    output = ""
    for section, param in pairs data
        if "table" == type param
            unless rec_sec
                output ..= ("\n[%s]\n")\format section
            else
                output ..= ("\n[%s.%s]\n")\format rec_sec, section
            for k, v in pairs param
                unless "table" == type v
                    if "string" == type v
                        output ..= ("%s = \"%s\"\n")\format k, tostring v
                    else
                        output ..= ("%s = %s\n")\format k, tostring v
                else
                    unless rec_sec
                        rec_sec = ("%s.%s")\format section, k
                    else
                        rec_sec = ("%s.%s.%s")\format rec_sec, section, k
                    output ..= ("\n[%s]\n")\format rec_sec
                    output ..= generate_ini v, rec_sec
        else
            if "string" == type param
                output ..= ("%s = \"%s\"\n")\format section, tostring param
            else
                output ..= ("%s = %s\n")\format section, tostring param

    output

export * -- messy. very messy... idc

load = (data, namespace = "data") ->

    output = {}
    section = ""

    i = 1 -- for keeping track of nested layer
    for line in (data .. "\n")\gmatch "(.-)\n"
        temp_section = line\match "^%[([^%[%]]+)%]$"

        if temp_section
            t = output
            for w, d in temp_section\gfind "([%w_]+)(.?)"
                t[w] = t[w] or {}
                t = t[w]

            section = temp_section

        p, v = line\match "^([%w|_]+)%s-=%s-(.+)$"

        if p and v
            if tonumber v
                v = v
            elseif v\match "true"
                v = true
            elseif v\match "false"
                v = false
            elseif v\match "\".-\""
                v = v\match "\"(.-)\""
            else
                error "unexpected value: " .. v

            if tonumber p
                p = tonumber p

            t = output
            for w, d in section\gfind "([%w_]+)(.?)"
                if d == "."
                    t[w] = t[w]
                    t = t[w]
                else
                    t[w][p] = v
        else
            unless temp_section or "" == line\gsub "^%s*(.-)%s*$", "%1"
                error "failed trying to match line: " .. line

    output[namespace]

generate = (data, namespace = "data") ->

    (generate_ini {[namespace]: data})
