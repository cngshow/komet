module TaxonomyHelper

    def get_tree_node_flag(flag_name, ids_to_match)

        flag = ''

        if session['color' + flag_name]

            colors = session['color' + flag_name].find_all{|key, hash|
                hash[flag_name + 'id'].to_i.in?(ids_to_match) && hash['colorid'] != ''
            }

            colors.each do |color|
                colorshape = ''
                if color[1]['colorshape'] != 'none'
                  colorshape= color[1]['colorshape']
                  flag = ' <span class="' + colorshape  + '" style="color: ' + color[1]['colorid'] + ';"></span>'
                else
                    flag = ' <span class="komet-node-' + flag_name + '-flag ' + colorshape  + '" style="border-color: ' + color[1]['colorid'] + ';"></span>'
                end

                           end
        end

        flag
    end
end
