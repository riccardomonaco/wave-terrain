/*
  ==============================================================================

    This file contains the basic framework code for a JUCE plugin editor.

  ==============================================================================
*/
#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
multiSaturatorAudioProcessorEditor::multiSaturatorAudioProcessorEditor(MultiSaturatorAudioProcessor& p)
    : AudioProcessorEditor(&p), audioProcessor(p)
{
    lowSlider.setSliderStyle(juce::Slider::RotaryHorizontalVerticalDrag);
    lowSlider.setTextBoxStyle(juce::Slider::TextBoxBelow, false, 50, 20);
    addAndMakeVisible(lowSlider);

    midSlider.setSliderStyle(juce::Slider::RotaryHorizontalVerticalDrag);
    midSlider.setTextBoxStyle(juce::Slider::TextBoxBelow, false, 50, 20);
    addAndMakeVisible(midSlider);

    highSlider.setSliderStyle(juce::Slider::RotaryHorizontalVerticalDrag);
    highSlider.setTextBoxStyle(juce::Slider::TextBoxBelow, false, 50, 20);
    addAndMakeVisible(highSlider);

    fbAmountSlider.setSliderStyle(juce::Slider::RotaryHorizontalVerticalDrag);
    fbAmountSlider.setTextBoxStyle(juce::Slider::TextBoxBelow, false, 50, 20);
    addAndMakeVisible(fbAmountSlider);

    fbTimeSlider.setSliderStyle(juce::Slider::RotaryHorizontalVerticalDrag);
    fbTimeSlider.setTextBoxStyle(juce::Slider::TextBoxBelow, false, 50, 20);
    addAndMakeVisible(fbTimeSlider);

    typeBox.addItem("Soft Clip", 1);
    typeBox.addItem("Hard Clip", 2);
    typeBox.addItem("Roar Fold", 3);
    addAndMakeVisible(typeBox);

    lowAttach = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(audioProcessor.apvts, "low_drive", lowSlider);
    midAttach = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(audioProcessor.apvts, "mid_drive", midSlider);
    highAttach = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(audioProcessor.apvts, "high_drive", highSlider);
    fbAmountAttach = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(audioProcessor.apvts, "fb_amount", fbAmountSlider);
    fbTimeAttach = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(audioProcessor.apvts, "fb_time", fbTimeSlider);

    typeAttach = std::make_unique<juce::AudioProcessorValueTreeState::ComboBoxAttachment>(audioProcessor.apvts, "sat_type", typeBox);

    setSize(720, 400); 
    startTimerHz(30);
}

multiSaturatorAudioProcessorEditor::~multiSaturatorAudioProcessorEditor() {}

void multiSaturatorAudioProcessorEditor::timerCallback()
{
    repaint();
}

//==============================================================================
void multiSaturatorAudioProcessorEditor::paint(juce::Graphics& g)
{
    g.fillAll(juce::Colours::darkgrey);
    g.setColour(juce::Colours::white);
    g.setFont(16.0f);

    // 6 columns
    int colWidth = getWidth() / 6;

    g.drawFittedText("Low", 0, 10, colWidth, 20, juce::Justification::centred, 1);
    g.drawFittedText("Mid", colWidth, 10, colWidth, 20, juce::Justification::centred, 1);
    g.drawFittedText("High", colWidth * 2, 10, colWidth, 20, juce::Justification::centred, 1);
    g.drawFittedText("FB %", colWidth * 3, 10, colWidth, 20, juce::Justification::centred, 1);
    g.drawFittedText("Time", colWidth * 4, 10, colWidth, 20, juce::Justification::centred, 1);
    g.drawFittedText("Mode", colWidth * 5, 10, colWidth, 20, juce::Justification::centred, 1);

    // Oscilloscope
    juce::Rectangle<int> scopeBounds(10, 200, getWidth() - 20, 180);
    g.setColour(juce::Colours::black);
    g.fillRect(scopeBounds);

    juce::Path scopePath;
    g.setColour(juce::Colours::green);
    int startPos = audioProcessor.scopePos.load();

    for (int i = 0; i < audioProcessor.scopeSize; ++i)
    {
        int readPos = (startPos + i) % audioProcessor.scopeSize;
        float sample = audioProcessor.scopeData[readPos];

        float x = scopeBounds.getX() + (i * scopeBounds.getWidth()) / (float)audioProcessor.scopeSize;
        float y = scopeBounds.getCentreY() - (sample * (scopeBounds.getHeight() / 2.0f));

        if (i == 0) scopePath.startNewSubPath(x, y);
        else        scopePath.lineTo(x, y);
    }
    g.strokePath(scopePath, juce::PathStrokeType(2.0f));
}

void multiSaturatorAudioProcessorEditor::resized()
{
    int colWidth = getWidth() / 6;

    lowSlider.setBounds(0, 40, colWidth, 150);
    midSlider.setBounds(colWidth, 40, colWidth, 150);
    highSlider.setBounds(colWidth * 2, 40, colWidth, 150);
    fbAmountSlider.setBounds(colWidth * 3, 40, colWidth, 150);
    fbTimeSlider.setBounds(colWidth * 4, 40, colWidth, 150);

    typeBox.setBounds(colWidth * 5 + 10, 100, colWidth - 20, 30);
}