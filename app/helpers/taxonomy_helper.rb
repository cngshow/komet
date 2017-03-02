module TaxonomyHelper

    def get_tree_node_flag(flag_name, ids_to_match)

        return_flags = ''
        user_prefs = user_session(UserSession::USER_PREFERENCES).nil? ? {} : user_session(UserSession::USER_PREFERENCES)
        $log.debug("get_tree_node_flag user_prefs[flag_name + '_flags'] #{user_prefs[flag_name + '_flags']}")

        if user_prefs[flag_name + '_flags']

            flags = user_prefs[flag_name + '_flags'].find_all{|key, hash|
                hash['id'].to_i.in?(ids_to_match) && hash['color'] != ''
            }

            $log.info("get_tree_node_flag flags #{flags}")
            flags.each do |flag|

                shape = ''
                caption = 'aria-label="' + flag[1]['text']  + ' Flag" title="' + flag[1]['text']  + ' Flag"'

                $log.debug("get_tree_node_flag flag[1]['shape'] #{flag[1]['shape']}")

                if flag[1]['shape'].downcase != 'none'
                    return_flags = ' <span class="' + flag[1]['shape']  + '" style="color: ' + flag[1]['color'] + ';" ' + caption + '></span>'
                else
                    return_flags = ' <span class="komet-node-' + flag_name + '-flag" style="border-color: ' + flag[1]['color'] + ';" ' + caption + '></span>'
                end

            end
        end

        return_flags
    end
end
