class Patient
  attr_accessor :patient_type, :name, :team, :original_team
  PATIENT_TYPE = [  'Type CSA',  'Type CNA',  'Type ASA',  'Type ANA',  'Type ASR',  'Type ANR',  'Type P',  'Type ACR',  'Type I',  'Type H',  'Type BR',  'Type BA']
  def initialize(patient_type:, name:, original_team: nil)
    @patient_type = patient_type
    @name = name
    @team = nil
    @original_team = original_team
  end
end
