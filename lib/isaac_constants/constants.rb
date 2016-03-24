begin
  require './lib/jars/ochre-api-3.01-SNAPSHOT.jar'
  java_import 'gov.vha.isaac.ochre.api.bootstrap.TermAux' do |p,c|
    'JTermAux'
  end
rescue Exception,LoadError=> ex #this exception handling need to be removed after maven builds our wars with the needed jars.
  $log.fatal("Could not load the TermAux.  The build did not build this war properly! " + ex.to_s)
  $log.fatal(ex.backtrace.join("\n"))
end

module ISAACConstants
  TERMAUX = {}
end

if Object.const_defined?("JTermAux")#refactor after maven build
  JTermAux.java_class.to_java.getDeclaredFields.each do |field|
    name = field.name
    uuid = JTermAux.java_class.to_java.getDeclaredField(name).get(JTermAux).getPrimordialUuid.to_s
    translated = IdAPIsRest::get_id(action: IdAPIsRestActions::ACTION_TRANSLATE,uuid_or_id: uuid)
    ISAACConstants::TERMAUX[name] = translated
  end
end


ISAACConstants::TERMAUX.freeze