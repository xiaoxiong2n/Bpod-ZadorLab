function [out] = GenerateSound(StimulusSettings)

SoundDuration = StimulusSettings.SoundDuration;
SoundFrequency = StimulusSettings.Freq;
SamplingRate = StimulusSettings.SamplingRate;
%SoundVolume = StimulusSettings.SoundVolume; 

ramp = StimulusSettings.Ramp; % Fraction of tone duration that is used for the envelope


toneVec = 1/SamplingRate:1/SamplingRate:SoundDuration;
omega=(acos(sqrt(0.1))-acos(sqrt(0.9)))/ramp; % This is for the envelope
t=0 : (1/SamplingRate) : pi/2/omega;
t=t(1:(end-1));
RaiseVec= (cos(omega*t)).^2;

Envelope = ones(length(toneVec),1); % This is the envelope
Envelope(1:length(RaiseVec)) = fliplr(RaiseVec);
Envelope(end-length(RaiseVec)+1:end) = (RaiseVec);
Envelope = repmat(Envelope,1,1);

out = (sin(toneVec'*SoundFrequency*2*pi).*Envelope)'; % Here are the enveloped tones as a matrix

return
