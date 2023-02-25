class Team
  RESIDENT_TEAM_TYPE = ['RIS 1 A', 'RIS 2 A', 'RIS 3 A', 'RIS 4 A', 'RIS 5 A', 'CARDS A']
  ATTENDING_TEAM_TYPE = ['FIS Green C', 'FIS Green A', 'FIS Red A', 'FIS Blue A', 'FIS Purple A']
  CALL_ASSIGNMENT = ["TINY CALL", "SHORT CALL", "LONG CALL", "PRE CALL", "POST CALL"]

  attr_accessor :id, :team_type, :name, :description, :census, :capacity, :call_assignment, :patients

  def initialize(id: nil, team_type:, name: nil, description: nil, census:, capacity:, call_assignment: nil)
    @id = id
    @team_type = team_type
    @name = name
    @description = description
    @census = census
    @capacity = capacity
    @call_assignment = call_assignment
    @patients = []
  end

  def add_patient(patient)
    if @census < @capacity
      @patients << patient
      patient.team = self
      @census += 1
      return true
    else
      return false
    end
  end

  def add_patient_ignore_cap(patient)
    @patients << patient
    patient.team = self
    @census += 1
    return true
  end

  def is_resident_team?
    RESIDENT_TEAM_TYPE.include?(team_type)
  end

  def is_attending_team?
    ATTENDING_TEAM_TYPE.include?(team_type)
  end
end
