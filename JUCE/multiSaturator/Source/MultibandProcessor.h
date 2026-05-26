/*
  ==============================================================================

    MultibandProcessor.h
    Created: 21 May 2026 8:33:13pm
    Author:  Davide

  ==============================================================================
*/

#pragma once
#include <JuceHeader.h>
#include "Waveshaper.h"

class MultibandProcessor
{
public:
    MultibandProcessor();

    void prepare(const juce::dsp::ProcessSpec& spec);
    void setCrossoverFrequencies(float lowMidFreq, float midHighFreq);
    void setDrives(float lowDrive, float midDrive, float highDrive);
    void process(juce::AudioBuffer<float>& buffer);

    void setSaturationType(int typeIndex);

private:
    juce::dsp::LinkwitzRileyFilter<float> lowPass1, highPass1;
    juce::dsp::LinkwitzRileyFilter<float> lowPass2, highPass2;
    juce::dsp::LinkwitzRileyFilter<float> allPass2;

    Waveshaper lowSaturator;
    Waveshaper midSaturator;
    Waveshaper highSaturator;

    juce::AudioBuffer<float> lowBuffer;
    juce::AudioBuffer<float> midBuffer;
    juce::AudioBuffer<float> highBuffer;
};