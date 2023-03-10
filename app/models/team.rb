class Team
  RESIDENT_TEAM_TYPE = ['RIS 1 A', 'RIS 2 A', 'RIS 3 A', 'RIS 4 A', 'RIS 5 A', 'CARDS A']
  ATTENDING_TEAM_TYPE = ['FIS Green C', 'FIS Green A', 'FIS Red A', 'FIS Blue A', 'FIS Purple A']
  CALL_ASSIGNMENT = ['TINY CALL', 'SHORT CALL', 'LONG CALL', 'PRE CALL', 'POST CALL']

  TEAM_TYPE_DESCRIPTION_MAPPING = {
    'RIS 1 A' => 'RIS 1 A (resident acute service)',
    'RIS 2 A' => 'RIS 2 A (resident acute service)',
    'RIS 3 A' => 'RIS 3 A (resident acute service)',
    'RIS 4 A' => 'RIS 4 A (resident acute service)',
    'RIS 5 A' => 'RIS 5 A (resident acute service)',
    'CARDS A' => 'CARDS A (cardiology acute service)',
    'FIS Green C' => 'FIS Green C (attending consult service)',
    'FIS Green A' => 'FIS Green A (attending acute service)',
    'FIS Red A' => 'FIS Red A (attending acute service)',
    'FIS Blue A' => 'FIS Blue A (attending acute service)',
    'FIS Purple A' => 'FIS Purple A (attending acute service)'
  }
  attr_accessor :id, :team_type, :name, :description, :census, :capacity, :call_assignment, :patients

  def initialize(team_type:, census:, capacity:, id: nil, name: nil, description: nil, call_assignment: nil)
    @id = id
    @team_type = team_type
    @name = name
    @description = description
    @census = census
    @capacity = capacity
    @call_assignment = call_assignment
    @patients = []
  end

  def self.team_type_value_label_hash
    result = {}
    TEAM_TYPE_DESCRIPTION_MAPPING.each do |type|
      result[type[0]] = { value: type[0], label: type[1] }
    end
    result
  end

  def add_patient(patient)
    if @census < @capacity
      @patients << patient
      patient.team = self
      @census += 1
      true
    else
      false
    end
  end

  def add_patient_ignore_cap(patient)
    @patients << patient
    patient.team = self
    @census += 1
    true
  end

  def is_resident_team?
    RESIDENT_TEAM_TYPE.include?(team_type)
  end

  def is_attending_team?
    ATTENDING_TEAM_TYPE.include?(team_type)
  end
end
