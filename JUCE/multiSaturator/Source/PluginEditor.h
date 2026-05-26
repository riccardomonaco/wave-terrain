/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/

#pragma once
#include <JuceHeader.h>
#include "PluginProcessor.h"

class multiSaturatorAudioProcessorEditor : public juce::AudioProcessorEditor,
    public juce::Timer
{
public:
    multiSaturatorAudioProcessorEditor(MultiSaturatorAudioProcessor&);
    ~multiSaturatorAudioProcessorEditor() override;

    void paint(juce::Graphics&) override;
    void resized() override;
    void timerCallback() override;

private:
    MultiSaturatorAudioProcessor& audioProcessor;

    juce::Slider lowSlider, midSlider, highSlider, fbAmountSlider, fbTimeSlider;
    juce::ComboBox typeBox; // NEW

    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> lowAttach;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> midAttach;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> highAttach;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> fbAmountAttach;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> fbTimeAttach;
    std::unique_ptr<juce::AudioProcessorValueTreeState::ComboBoxAttachment> typeAttach; // NEW

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(multiSaturatorAudioProcessorEditor)
};