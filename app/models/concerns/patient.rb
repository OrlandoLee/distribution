class Patient
  attr_accessor :id, :patient_type, :name, :team, :original_team

  PATIENT_TYPE = ['Type CSA',  'Type CNA',  'Type ASA', 'Type ANA', 'Type ASR', 'Type ANR', 'Type P',
                  'Type ACR', 'Type I', 'Type H', 'Type BR', 'Type BA']
  PATIENT_TYPE_WITH_DEFINITION = ['Type CSA (New Consults done by Attending on Swing Shift)',
                                  'Type CNA (New Consults done by Attending on Night Shift)', 'Type ASA (New Admissions done by Attending on Swing Shift)', 'Type ANA (New Admissions done by Attending on Night Shift)', 'Type ASR (New Admissions done by Resident on Swing Shift)', 'Type ANR (New Admissions done by Resident on Night Shift)', 'Type P (Pending Admissions)', 'Type ACR (New Admissions done by Cardiology Resident)', 'Type I (ICU Downgrades)', 'Type H (ICU Holds)', 'Type BR (Bounceback to Resident Teams)', 'Type BA (Bounceback to Attending Teams)']
  def self.patient_type_value_label_hash
    result = {}
    PATIENT_TYPE.each_with_index do |type, i|
      result[type] = { value: type, label: PATIENT_TYPE_WITH_DEFINITION[i] }
    end
    result
  end

  def initialize(id: nil, patient_type: nil, name: nil, original_team: nil)
    @id = id
    @patient_type = patient_type
    @name = name
    @team = nil
    @original_team = original_team
  end
end
