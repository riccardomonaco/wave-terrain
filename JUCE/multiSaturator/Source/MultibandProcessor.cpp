/*
  ==============================================================================

    MultibandProcessor.cpp

  ==============================================================================
*/

#include "MultibandProcessor.h"


MultibandProcessor::MultibandProcessor() {}

void MultibandProcessor::prepare(const juce::dsp::ProcessSpec& spec)
{
    lowPass1.prepare(spec); lowPass1.setType(juce::dsp::LinkwitzRileyFilterType::lowpass);
    highPass1.prepare(spec); highPass1.setType(juce::dsp::LinkwitzRileyFilterType::highpass);

    lowPass2.prepare(spec); lowPass2.setType(juce::dsp::LinkwitzRileyFilterType::lowpass);
    highPass2.prepare(spec); highPass2.setType(juce::dsp::LinkwitzRileyFilterType::highpass);

    allPass2.prepare(spec); allPass2.setType(juce::dsp::LinkwitzRileyFilterType::allpass);

    lowBuffer.setSize(spec.numChannels, spec.maximumBlockSize);
    midBuffer.setSize(spec.numChannels, spec.maximumBlockSize);
    highBuffer.setSize(spec.numChannels, spec.maximumBlockSize);
}

void MultibandProcessor::setCrossoverFrequencies(float lowMidFreq, float midHighFreq)
{
    lowPass1.setCutoffFrequency(lowMidFreq);
    highPass1.setCutoffFrequency(lowMidFreq);

    lowPass2.setCutoffFrequency(midHighFreq);
    highPass2.setCutoffFrequency(midHighFreq);
    allPass2.setCutoffFrequency(midHighFreq);
}

void MultibandProcessor::setDrives(float lowDrive, float midDrive, float highDrive)
{
    lowSaturator.setDrive(lowDrive);
    midSaturator.setDrive(midDrive);
    highSaturator.setDrive(highDrive);
}

void MultibandProcessor::process(juce::AudioBuffer<float>& buffer)
{
    auto numChannels = buffer.getNumChannels();
    auto numSamples = buffer.getNumSamples();

    for (int ch = 0; ch < numChannels; ++ch)
    {
        lowBuffer.copyFrom(ch, 0, buffer, ch, 0, numSamples);
        midBuffer.copyFrom(ch, 0, buffer, ch, 0, numSamples);
    }

    juce::dsp::AudioBlock<float> lowBlock(lowBuffer);
    juce::dsp::AudioBlock<float> midBlock(midBuffer);
    juce::dsp::AudioBlock<float> highBlock(highBuffer);

    lowPass1.process(juce::dsp::ProcessContextReplacing<float>(lowBlock));
    highPass1.process(juce::dsp::ProcessContextReplacing<float>(midBlock));

    for (int ch = 0; ch < numChannels; ++ch)
    {
        highBuffer.copyFrom(ch, 0, midBuffer, ch, 0, numSamples);
    }

    lowPass2.process(juce::dsp::ProcessContextReplacing<float>(midBlock));
    highPass2.process(juce::dsp::ProcessContextReplacing<float>(highBlock));

    allPass2.process(juce::dsp::ProcessContextReplacing<float>(lowBlock));

    lowSaturator.process(lowBuffer);
    midSaturator.process(midBuffer);
    highSaturator.process(highBuffer);

    buffer.clear();
    for (int ch = 0; ch < numChannels; ++ch)
    {
        buffer.addFrom(ch, 0, lowBuffer, ch, 0, numSamples);
        buffer.addFrom(ch, 0, midBuffer, ch, 0, numSamples);
        buffer.addFrom(ch, 0, highBuffer, ch, 0, numSamples);
    }
}

void MultibandProcessor::setSaturationType(int typeIndex)
{
    Waveshaper::Type newType = static_cast<Waveshaper::Type>(typeIndex);

    lowSaturator.setType(newType);
    midSaturator.setType(newType);
    highSaturator.setType(newType);
}   