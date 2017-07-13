module TaxonomyHelper

    def get_tree_node_flag(flag_name, ids_to_match)

        return_flags = ''
        user_prefs = user_session(UserSession::USER_PREFERENCES).nil? ? {} : user_session(UserSession::USER_PREFERENCES)

        if user_prefs[flag_name + '_flags']

            # TODO - Switch to this code once the coord code and stamp sequences are switched to passing UUIDS
            if flag_name == 'refset'

                flags = user_prefs[flag_name + '_flags'].select{|key, hash|

                    found = false

                    ids_to_match.each { |id|

                        if id.uuids.first == hash['id'] && (hash['color'] != '' || hash['shape_name'].downcase != 'none')
                            found = true
                            break
                        end
                    }

                    found
                }
            else

                flags = user_prefs[flag_name + '_flags'].select{|key, hash|
                    hash['id'].to_i.in?(ids_to_match) && (hash['color'] != '' || hash['shape_name'].downcase != 'none')
                }
            end

            flags.each do |flag|

                shape = 'rectangle'
                color = 'black'

                if flag[1]['shape_name'].downcase != 'none'
                    shape = flag[1]['shape_name']
                end

                if flag[1]['color'] != ''
                    color = flag[1]['color']
                end

                caption = 'aria-label="' + flag[1]['text']  + ' Flag, Color: ' + color + ', Shape: ' + shape + '" title="' + flag[1]['text']  + ' Flag"'

                if flag[1]['shape_class'].downcase != 'none'
                    return_flags << ' <span class="' + flag[1]['shape_class']  + '" style="color: ' + flag[1]['color'] + ';" ' + caption + '></span>'
                else
                    return_flags << ' <span class="komet-node-' + flag_name + '-flag" style="border-color: ' + flag[1]['color'] + ';" ' + caption + '></span>'
                end

            end
        end

        return_flags
    end
end
