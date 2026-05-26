/*
  ==============================================================================

    Waveshaper.h

  ==============================================================================
*/

#pragma once
#include <JuceHeader.h>

class Waveshaper
{
public:
    Waveshaper();

    enum class Type { SoftClip, HardClip, RoarFold };

    void setDrive(float newDrive);
    void setType(Type newType); // NEW
    void process(juce::AudioBuffer<float>& buffer);

private:
    float drive = 1.0f;
    Type currentType = Type::SoftClip; // Default
};