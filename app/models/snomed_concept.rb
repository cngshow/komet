class SnomedConcept < ActiveResource::Base
  self.site = $PROPS['ENDPOINT.snomed_concepts']

  schema do
    string 'concept_id', 'fsn', 'preferred_name', 'id'
  end

 # self.element_name = "snomed_concepts"
  validates_presence_of(:concept_id, :fsn)

end

=begin
"snomed_concept"=>{"concept_id"=>"10", "fsn"=>"BoB2", "preferred_name"=>"Billy"}
 a = SnomedConcept.find('5696934f8726e30e4f000001')

 s= SnomedConcept.new
  s.concept_id="115425"
 s.fsn="Greg22"
 s.preferred_name="2Bowman22"

get:
hash = SnomedConcept.get('5696934f8726e30e4f000001') (returns a hash)
SnomedConcept.find('5696934f8726e30e4f000001') (returns SnomedConcept)
puts hash.inspect
put (an edit / update):
 SnomedConcept.put('5697f1228726e38b6a000007',snomed_concept: {fsn: "KMA!!!"})
 SnomedConcept.patch('5696934f8726e30e4f000001',snomed_concept: {fsn: "KMA!!!"})

Delete:
SnomedConcept.find('5696aba68726e36008000001').destroy
SnomedConcept.delete('56969b548726e36042000001')

=end

=begin
> rake routes
             Prefix Verb   URI Pattern                         Controller#Action
    snomed_concepts GET    /snomed_concepts(.:format)          snomed_concepts#index
                    POST   /snomed_concepts(.:format)          snomed_concepts#create
 new_snomed_concept GET    /snomed_concepts/new(.:format)      snomed_concepts#new
edit_snomed_concept GET    /snomed_concepts/:id/edit(.:format) snomed_concepts#edit
     snomed_concept GET    /snomed_concepts/:id(.:format)      snomed_concepts#show
                    PATCH  /snomed_concepts/:id(.:format)      snomed_concepts#update
                    PUT    /snomed_concepts/:id(.:format)      snomed_concepts#update
                    DELETE /snomed_concepts/:id(.:format)      snomed_concepts#destroy

=end