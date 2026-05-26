/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin processor.

  ==============================================================================
*/

#pragma once

#include <JuceHeader.h>
#include <atomic>
#include "MultibandProcessor.h"

//==============================================================================
/**
*/
class MultiSaturatorAudioProcessor  : public juce::AudioProcessor
{
public:
    //==============================================================================
    MultiSaturatorAudioProcessor();
    ~MultiSaturatorAudioProcessor() override;

    //==============================================================================
    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

   #ifndef JucePlugin_PreferredChannelConfigurations
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
   #endif

    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    //==============================================================================
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    //==============================================================================
    const juce::String getName() const override;

    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    //==============================================================================
    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    //==============================================================================
    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;

    static juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();
    juce::AudioProcessorValueTreeState apvts;


    // --- OSCILLOSCOPE VARIABLES ---
    static constexpr int scopeSize = 512;        
    float scopeData[scopeSize] = { 0.0f };       
    std::atomic<int> scopePos{ 0 };

    // --- FEEDBACK / DELAY VARIABLES ---
    juce::AudioBuffer<float> delayBuffer;
    std::vector<int> delayWritePosition{ 0, 0 };
    double currentSampleRate = 44100.0;
    juce::AudioBuffer<float> feedbackBuffer;
    std::array<juce::dsp::StateVariableTPTFilter<float>, 2> fbFilters;
    juce::dsp::Compressor<float> fbCompressor;

private:
    MultibandProcessor multibandProcessor;
    juce::Reverb outputReverb;
    
    //==============================================================================
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MultiSaturatorAudioProcessor)
};
