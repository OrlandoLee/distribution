class DistributionsController < ApplicationController
  def enter_value
    @all_teams = []
    [Team::RESIDENT_TEAM_TYPE + Team::ATTENDING_TEAM_TYPE].flatten.each_with_index do |team_type, index|
      @all_teams << Team.new(id: index, team_type: team_type, census: 10, capacity: 15)
    end

    @all_patients = []
    (params[:number_of_patients] || 10).to_i.times do |i|
      @all_patients << Patient.new(id: i)
    end
  end

  def distribute
    @cardiology_admission = 10
    @all_teams = []
    @all_patients = []
    params.permit![:all_teams][:teams].each do |id, team|
      @all_teams << Team.new(team_type: team[:team_type], census: team[:census].to_i, capacity: team[:capacity].to_i, call_assignment: team[:call_assignment])
    end

    params.permit![:all_teams][:patients].each do |id, patient|
      if(patient[:name].present?)
        @all_patients << Patient.new(patient_type: patient[:patient_type], name: patient[:name], original_team: patient[:original_team])
      end
    end

    assign_bouncebacks(patients: @all_patients, teams: @all_teams)
    assign_patients(patients: @all_patients, all_teams: @all_teams)
  end

  private 

  def assign_bouncebacks(patients: , teams: )
    # Assign all Bouncebacks (patients of type BR and BA) to their respective teams unless those teams are already at capacity.
    # If the teams to which a patient should return are at capacity, and a bounceback cannot return to its original team,
    # Type BR patients can be assigned to any resident team and type BA patients can be assigned to any attending team.
  
    patients.each do |patient|
      if patient.patient_type == "BR"
        original_team = teams.select{|team| team.team_type == patient.original_team}.first
        if(original_team.present?)
          if original_team.add_patient(patient)
            puts "Patient #{patient.name} (Type BR) assigned to team #{patient.team.name}"
          else
            assigned = false
            teams.each do |team|
              if team.is_resident_team? && team.add_patient(patient)
                puts "Patient #{patient.name} (Type BR) assigned to team #{team.name}"
                assigned = true
                break
              end
            end
            if !assigned
              puts "Patient #{patient.name} (Type BR) could not be assigned to any team"
            end
          end
        else
          p 'NEED TO HAVE ORIGINAL TEAM'
        end
      elsif patient.patient_type == "BA"
        original_team = teams.select{|team| team.team_type == patient.original_team}.first
        if(original_team.present?)
          if original_team.add_patient(patient)
            puts "Patient #{patient.name} (Type BA) assigned to team #{patient.team.name}"
          else
            assigned = false
            teams.each do |team|
              if team.is_attending_team? && team.add_patient(patient)
                puts "Patient #{patient.name} (Type BA) assigned to team #{team.name}"
                assigned = true
                break
              end
            end
            if !assigned
              puts "Patient #{patient.name} (Type BA) could not be assigned to any team"
            end
          end
        else
          p 'NEED TO HAVE ORIGINAL TEAM'
        end
      end
    end
  end

  # main method to assign patients to teams
  def assign_patients(patients:, all_teams:)
    # Step 1
    fis_green_c_team = all_teams.select{|team| team.team_type == "FIS Green C"}.first
    if(fis_green_c_team.present?)
      puts "Starting Census for FIS Green C: #{fis_green_c_team.census}"
      type_csa_cna = patients.select { |p| p.patient_type == "Type CSA" || p.patient_type == "Type CNA" }
      fis_green_c_received = 0
      type_csa_cna.each do |p|
        # some patients may not be added because of capacity
        if(fis_green_c_team.add_patient(p))
          fis_green_c_received += 1
        end
      end
    else
      p '------NO FIS Green C team'
    end

    # Step 2
    fis_green_a_team = all_teams.select{|team| team.team_type == "FIS Green A"}.first
    if(fis_green_a_team.present?)
      fis_green_a_received = 0
      if fis_green_c_received >= 2
        puts "FIS Green A will not receive any patients in Step 2"
      elsif fis_green_c_received == 1
        ["Type ACR", "Type ASA", "Type ANA", "Type ASR", "Type ANR"].each do |patient_type|
          selected_patients = patients.select do |p|
            p.patient_type == patient_type && !p.team.present?
          end
          selected_patients.each do |p|
            if(fis_green_a_received < 1)
              if(fis_green_a_team.add_patient(p))
                fis_green_a_received += 1
              end
            end
          end
        end
      else
        ["Type ACR", "Type ASA", "Type ANA", "Type ASR", "Type ANR"].each do |patient_type|
          selected_patients = patients.select do |p|
            p.patient_type == patient_type && !p.team.present?
          end
          selected_patients.each do |p|
            if(fis_green_a_received < 2)
              if(fis_green_a_team.add_patient(p))
                fis_green_a_received += 1
              end
            end
          end
        end
      end
    end

    # Step 3
    tiny_call_team = all_teams.select{|team| team.call_assignment == "TINY CALL"}.first
    if(tiny_call_team.present?)
      tiny_call_team_received = 0
      # Assign up to 2 patients based on priority
      ['Type ASR', 'Type ANR', 'Type ASA', 'Type ANA'].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(tiny_call_team_received < 2 && tiny_call_team.census < 15)
            if(tiny_call_team.add_patient(p))
              tiny_call_team_received += 1
            end
          end
        end
      end
    end


    # Step 4
    fis_purple_a_team = all_teams.select{|team| team.team_type == "FIS Purple A"}.first
    if(fis_purple_a_team.present?)
      fis_purple_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_purple_a_received < 1 && fis_purple_a_team.census < 10)
            if(fis_purple_a_team.add_patient(p))
              fis_purple_a_received += 1
            end
          end
        end
      end
    end
   
    # Step 5
    fis_red_a_team = all_teams.select{|team| team.team_type == "FIS Red A"}.first
    if(fis_red_a_team.present?)
      fis_red_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_purple_a_received < 1 && fis_purple_a_team.census < 12)
            if(fis_purple_a_team.add_patient(p))
              fis_purple_a_received += 1
            end
          end
        end
      end
    end

    # Step 6
    fis_blue_a_team = all_teams.select{|team| team.team_type == "FIS Blue A"}.first
    if(fis_blue_a_team.present?)
      fis_blue_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_blue_a_received < 1 && fis_blue_a_team.census < 12)
            if(fis_blue_a_team.add_patient(p))
            fis_blue_a_received += 1
            end
          end
        end
      end
    end

    # Step 7
    short_call_team = all_teams.select{|team| team.call_assignment == "SHORT CALL"}.first
    if(short_call_team.present?)
      short_call_team_received = 0
      # Assign up to 2 patients based on priority
      ['Type P', 'Type ASR', 'Type ANR', 'Type ASA', 'Type ANA', 'Type ACR'].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(short_call_team_received < 2 && short_call_team.census < 15)
            if(short_call_team.add_patient(p))
              short_call_team_received += 1
            end
          end
        end 
      end
    end

    # Step 8
    fis_green_a_team = all_teams.select{|team| team.team_type == "FIS Green A"}.first
    if(fis_green_a_team.present?)
      fis_green_a_received = 0
      ["Type ACR", "Type ASA", "Type ANA", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_green_a_received < 1 && fis_green_a_team.census < 6)
            if(fis_green_a_team.add_patient(p))
              fis_green_a_received += 1
            end
          end
        end
      end
    end

    # Step 9
    fis_purple_a_team = all_teams.select{|team| team.team_type == "FIS Purple A"}.first
    if(fis_purple_a_team.present?)
      fis_purple_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_purple_a_received < 1 && fis_purple_a_team.census < 10)
            if(fis_purple_a_team.add_patient(p))
              fis_purple_a_received += 1
            end
          end
        end
      end
    end
    
    # Step 10
    fis_blue_a_team = all_teams.select{|team| team.team_type == "FIS Blue A"}.first
    if(fis_blue_a_team.present?)
      fis_blue_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_blue_a_received < 1 && fis_blue_a_team.census < 12)
            if(fis_blue_a_team.add_patient(p))
            fis_blue_a_received += 1
            end
          end
        end
      end
    end


    # Step 11
    fis_red_a_team = all_teams.select{|team| team.team_type == "FIS Red A"}.first
    if(fis_red_a_team.present?)
      fis_red_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_purple_a_received < 1 && fis_purple_a_team.census < 12)
            if(fis_purple_a_team.add_patient(p))
              fis_purple_a_received += 1
            end
          end
        end
      end
    end


    # Step 12
    long_call_team = all_teams.select{|team| team.call_assignment == "LONG CALL"}.first
    if(long_call_team.present?)
      long_call_team_received = 0

      # Assign up to 2 patients based on priority
      ['Type ASR', 'Type ANR', 'Type ASA', 'Type ANA', 'Type P', 'Type ACR'].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(long_call_team_received < 2 && long_call_team.census < 10)
            if(long_call_team.add_patient(p))
              long_call_team_received += 1
            end
          end
        end
      end
    end


    # Step 13
    fis_green_a_team = all_teams.select{|team| team.team_type == "FIS Green A"}.first
    if(fis_green_a_team.present?)
      fis_green_a_received = 0
      ["Type ACR", "Type ASA", "Type ANA", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_green_a_received < 1 && fis_green_a_team.census < 6)
            if(fis_green_a_team.add_patient(p))
              fis_green_a_received += 1
            end
          end
        end
      end
    end


    # Step 14
    fis_purple_a_team = all_teams.select{|team| team.team_type == "FIS Purple A"}.first
    if(fis_purple_a_team.present?)
      fis_purple_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_purple_a_received < 1 && fis_purple_a_team.census < 10)
            if(fis_purple_a_team.add_patient(p))
              fis_purple_a_received += 1
            end
          end
        end
      end
    end


    # Step 15
    fis_red_a_team = all_teams.select{|team| team.team_type == "FIS Red A"}.first
    if(fis_red_a_team.present?)
      fis_red_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_purple_a_received < 1 && fis_purple_a_team.census < 12)
            if(fis_purple_a_team.add_patient(p))
              fis_purple_a_received += 1
            end
          end
        end
      end
    end

    # Step 16
    fis_blue_a_team = all_teams.select{|team| team.team_type == "FIS Blue A"}.first
    if(fis_blue_a_team.present?)
      fis_blue_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_blue_a_received < 1 && fis_blue_a_team.census < 12)
            if(fis_blue_a_team.add_patient(p))
            fis_blue_a_received += 1
            end
          end
        end
      end
    end
 

    # Step 17
    short_call_team = all_teams.select{|team| team.call_assignment == "SHORT CALL"}.first
    if(short_call_team.present?)
      short_call_team_received = 0
      # Assign up to 2 patients based on priority
      ['Type P', 'Type ASR', 'Type ANR', 'Type ASA', 'Type ANA', 'Type ACR'].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(short_call_team_received < 2 && short_call_team.census < 15)
            if(short_call_team.add_patient(p))
              short_call_team_received += 1
            end
          end
        end
      end
    end
    

    # Step 18
    fis_purple_a_team = all_teams.select{|team| team.team_type == "FIS Purple A"}.first
    if(fis_purple_a_team.present?)
      fis_purple_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_purple_a_received < 1 && fis_purple_a_team.census < 10)
            if(fis_purple_a_team.add_patient(p))
              fis_purple_a_received += 1
            end
          end
        end
      end
    end

    # Step 19
    fis_blue_a_team = all_teams.select{|team| team.team_type == "FIS Blue A"}.first
    if(fis_blue_a_team.present?)
      fis_blue_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_blue_a_received < 1 && fis_blue_a_team.census < 12)
            if(fis_blue_a_team.add_patient(p))
            fis_blue_a_received += 1
            end
          end
        end
      end
    end
    

    # Step 20
    fis_red_a_team = all_teams.select{|team| team.team_type == "FIS Red A"}.first
    if(fis_red_a_team.present?)
      fis_red_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_purple_a_received < 1 && fis_purple_a_team.census < 12)
            if(fis_purple_a_team.add_patient(p))
              fis_purple_a_received += 1
            end
          end
        end
      end
    end
    

    # Step 21
    long_call_team = all_teams.select{|team| team.call_assignment == "LONG CALL"}.first
    if(long_call_team.present?)
      long_call_team_received = 0
      # Assign up to 2 patients based on priority
      ['Type ASR', 'Type ANR', 'Type ASA', 'Type ANA', 'Type P', 'Type ACR'].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(long_call_team_received < 3 && long_call_team.census < 13)
            if(long_call_team.add_patient(p))
              long_call_team_received += 1
            end
          end
        end
      end
    end
    
    # extra step
    pass_step_22 = patients.select do |p|
      ['Type CSA','Type CNA','Type ASA','Type ANA','Type ASR','Type ANR','Type P','Type ACR'].include?(p.patient_type) && !p.team.present?
    end.present?

    # Step 22
    cards_a_team = all_teams.select{|team| team.team_type == "CARDS A"}.first
    if(fis_green_a_team.present?)
      cards_a_received = 0
      cardiology_admission = @cardiology_admission
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(cardiology_admission < 7 && cards_a_received < 1 && fis_purple_a_team.census < 21)
            if(cards_a_team.add_patient(p))
              cards_a_received += 1
            end
          end
        end 
      end
    end
   

    # Step 23
    # Handle Type I Patient
    if(pass_step_22)
      selected_patients = patients.select do |p|
        p.patient_type == 'Type I' && !p.team.present?
      end
      selected_patients.each do |p|
        p.patient_type = 'Type H'
      end
    else
      selected_patients = patients.select do |p|
        p.patient_type == 'Type I' && !p.team.present?
      end
      selected_patients.each do |patient|
        all_teams.each do |team|
          if(team.add_patient(patient))
            break
          end
        end
      end
    end
    
    # Step 24
    fis_purple_a_team = all_teams.select{|team| team.team_type == "FIS Purple A"}.first
    if(fis_purple_a_team.present?)
      fis_purple_a_team.capacity = 12
      fis_purple_a_received = 0
      ["Type ASA", "Type ANA", "Type ACR", "Type ASR", "Type ANR"].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(fis_purple_a_received < 2 && fis_purple_a_team.census < 12)
            if(fis_purple_a_team.add_patient(p))
              fis_purple_a_received += 1
              p.patient_type = 'SUPERCAP'
            end
          end
        end
      end
    end
    
    # Step 25
    long_call_team = all_teams.select{|team| team.call_assignment == "LONG CALL"}.first
    if(long_call_team.present?)
      long_call_team_received = 0
      # Assign up to 2 patients based on priority
      ['Type P', 'Type ASR', 'Type ANR', 'Type ASA', 'Type ANA', 'Type ACR'].each do |patient_type|
        selected_patients = patients.select do |p|
          p.patient_type == patient_type && !p.team.present?
        end
        selected_patients.each do |p|
          if(long_call_team_received < 2 && long_call_team.census < 16)
            if(long_call_team.add_patient_ignore_cap(p))
              long_call_team_received += 1
            end
          end
        end
      end
    end
    

    # Last step
    patients.each do |p|
      if(p.patient_type != 'Type H' && !p.team.present?)
        p.patient_type = 'Type S'
      end
    end
  end
end
