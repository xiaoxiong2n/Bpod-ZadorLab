classdef BpodObject < handle
    %STATEMACHINEOBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        StateMatrix
        Birthdate
        LastTimestamp
        CurrentStateCode
        LastStateCode
        CurrentStateName
        LastStateName
        LastEvent
        LastTrialData
        SessionData
        LastHardwareState
        HardwareState
        BNCOverrideState
        GUIHandles
        GUIData
        Graphics
        EventNames
        OutputActionNames
        BeingUsed
        InStateMatrix
        Live
        CurrentProtocolName
        SerialPort
        Stimuli
        FirmwareBuild
        SplashData
        ProtocolSettings
        Data
        BpodPath
        SettingsPath
        DataPath
        ProtocolPath
        InputConfigPath
        InputsEnabled
        PluginSerialPorts
        PluginFigureHandles
        PluginObjects
        UsesPsychToolbox
        SystemSettings
        SoftCodeHandlerFunction
        ProtocolFigures
        Emulator % A struct with the internal variables of the emulator (analog of state machine workspace in Arduino)
        EmulatorMode % 0 if actual device, 1 if emulator
        ManualOverrideFlag % Used in the emulator to indicate an override that needs to be handled
        VirtualManualOverrideBytes % Stores emulated event bytes generated by override
        CalibrationTables % Struct for liquid, sound, etc.
        BlankStateMatrix % Holds a blank state matrix for fast initialization of a new state matrix.
    end
    
    methods
        
    end
    
end

