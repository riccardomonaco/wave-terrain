/*
  ==============================================================================

    Waveshaper.cpp

  ==============================================================================
*/

#pragma once
#include "Waveshaper.h"

Waveshaper::Waveshaper() {}

void Waveshaper::setDrive(float newDrive)
{
    drive = juce::jmax(1.0f, newDrive);
}

void Waveshaper::setType(Type newType)
{
    currentType = newType;
}

void Waveshaper::process(juce::AudioBuffer<float>& buffer)
{

    float autoMakeup = 1.0f / std::cbrt(drive);

    for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
    {
        float* channelData = buffer.getWritePointer(channel);

        for (int sample = 0; sample < buffer.getNumSamples(); ++sample)
        {
            float input = channelData[sample] * drive;
            float output = 0.0f;

            switch (currentType)
            {
            case Type::SoftClip:
                output = std::tanh(input);
                break;

            case Type::HardClip:
                output = juce::jlimit(-1.0f, 1.0f, input);
                break;

            case Type::RoarFold:
                float biased = std::tanh(input + 1.0f) - std::tanh(1.0f);
                output = std::sin(biased * 2.0f);
                break;
            }

            channelData[sample] = output * autoMakeup;
        }
    }
}