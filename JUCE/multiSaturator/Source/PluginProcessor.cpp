/*
  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
juce::AudioProcessorValueTreeState::ParameterLayout MultiSaturatorAudioProcessor::createParameterLayout()
{
    std::vector<std::unique_ptr<juce::RangedAudioParameter>> params;

    params.push_back(std::make_unique<juce::AudioParameterFloat>("low_drive", "Low Drive", 1.0f, 250.0f, 1.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("mid_drive", "Mid Drive", 1.0f, 250.0f, 1.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("high_drive", "High Drive", 1.0f, 250.0f, 1.0f));

    params.push_back(std::make_unique<juce::AudioParameterFloat>("low_mid_freq", "L/M Xover (Hz)", 20.0f, 1000.0f, 200.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("mid_high_freq", "M/H Xover (Hz)", 1000.0f, 20000.0f, 2000.0f));

    params.push_back(std::make_unique<juce::AudioParameterFloat>("fb_amount", "Feedback %", 0.0f, 150.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fb_time", "Delay (ms)", 1.0f, 250.0f, 250.0f));

    params.push_back(std::make_unique<juce::AudioParameterFloat>("reverb", "Reverb Amount", 0.0f, 1.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("room_size", "Room Size", 0.0f, 0.95f, 0.85f));

    juce::NormalisableRange<float> freqRange(20.0f, 20000.0f, 1.0f, 0.3f);
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fb_freq", "FB Freq (Hz)", freqRange, 1000.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("fb_q", "FB Q (Width)", 0.1f, 10.0f, 1.0f));

    juce::StringArray saturationTypes = { "Soft Clip", "Hard Clip", "Roar Fold" };
    params.push_back(std::make_unique<juce::AudioParameterChoice>("sat_type", "Type", saturationTypes, 0));

    return { params.begin(), params.end() };
}

//==============================================================================
MultiSaturatorAudioProcessor::MultiSaturatorAudioProcessor()
#ifndef JucePlugin_PreferredChannelConfigurations
    : AudioProcessor(BusesProperties()
#if ! JucePlugin_IsMidiEffect
#if ! JucePlugin_IsSynth
        .withInput("Input", juce::AudioChannelSet::stereo(), true)
#endif
        .withOutput("Output", juce::AudioChannelSet::stereo(), true)
#endif
    ),
    apvts(*this, nullptr, "Parameters", createParameterLayout())
#endif
{
}

MultiSaturatorAudioProcessor::~MultiSaturatorAudioProcessor()
{
}

//==============================================================================
const juce::String MultiSaturatorAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool MultiSaturatorAudioProcessor::acceptsMidi() const
{
#if JucePlugin_WantsMidiInput
    return true;
#else
    return false;
#endif
}

bool MultiSaturatorAudioProcessor::producesMidi() const
{
#if JucePlugin_ProducesMidiOutput
    return true;
#else
    return false;
#endif
}

bool MultiSaturatorAudioProcessor::isMidiEffect() const
{
#if JucePlugin_IsMidiEffect
    return true;
#else
    return false;
#endif
}

double MultiSaturatorAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int MultiSaturatorAudioProcessor::getNumPrograms()
{
    return 1;
}

int MultiSaturatorAudioProcessor::getCurrentProgram()
{
    return 0;
}

void MultiSaturatorAudioProcessor::setCurrentProgram(int index)
{
}

const juce::String MultiSaturatorAudioProcessor::getProgramName(int index)
{
    return {};
}

void MultiSaturatorAudioProcessor::changeProgramName(int index, const juce::String& newName)
{
}

//==============================================================================
void MultiSaturatorAudioProcessor::prepareToPlay(double sampleRate, int samplesPerBlock)
{
    juce::dsp::ProcessSpec spec;
    spec.maximumBlockSize = samplesPerBlock;
    spec.sampleRate = sampleRate;
    spec.numChannels = getTotalNumOutputChannels();

    multibandProcessor.prepare(spec);
    multibandProcessor.setCrossoverFrequencies(apvts.getRawParameterValue("low_mid_freq")->load(), apvts.getRawParameterValue("mid_high_freq")->load());

    currentSampleRate = sampleRate;

    delayBuffer.setSize(getTotalNumOutputChannels(), (int)(sampleRate * 2.0));
    delayBuffer.clear();

    delayWritePosition.resize(getTotalNumOutputChannels(), 0);
    feedbackBuffer.setSize(getTotalNumOutputChannels(), samplesPerBlock);

    for (auto& filter : fbFilters)
    {
        filter.prepare(spec);
        filter.setType(juce::dsp::StateVariableTPTFilterType::bandpass);
    }

    fbCompressor.prepare(spec);
    fbCompressor.setThreshold(-12.0f); 
    fbCompressor.setRatio(20.0f);
    fbCompressor.setAttack(1.0f);
    fbCompressor.setRelease(50.0f);

    outputReverb.setSampleRate(sampleRate);

    juce::Reverb::Parameters reverbParams;
    reverbParams.roomSize = 0.0f;
    reverbParams.damping = 0.2f;

    reverbParams.wetLevel = 0.0f;
    reverbParams.dryLevel = 1.0f - reverbParams.wetLevel;

    reverbParams.width = 1.0f;
    outputReverb.setParameters(reverbParams);
}

void MultiSaturatorAudioProcessor::releaseResources()
{
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool MultiSaturatorAudioProcessor::isBusesLayoutSupported(const BusesLayout& layouts) const
{
#if JucePlugin_IsMidiEffect
    juce::ignoreUnused(layouts);
    return true;
#else
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
        && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

#if ! JucePlugin_IsSynth
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;
#endif

    return true;
#endif
}
#endif

//==============================================================================
// 5. THE MAIN AUDIO LOOP
void MultiSaturatorAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    for (auto i = getTotalNumInputChannels(); i < totalNumOutputChannels; ++i)
        buffer.clear(i, 0, buffer.getNumSamples());

    float low = apvts.getRawParameterValue("low_drive")->load();
    float mid = apvts.getRawParameterValue("mid_drive")->load();
    float high = apvts.getRawParameterValue("high_drive")->load();

    float lowMidCut = apvts.getRawParameterValue("low_mid_freq")->load();
    float midHighCut = apvts.getRawParameterValue("mid_high_freq")->load();

    float fbAmount = apvts.getRawParameterValue("fb_amount")->load();
    float fbTime = apvts.getRawParameterValue("fb_time")->load();
    float fbFreq = apvts.getRawParameterValue("fb_freq")->load();
    float fbQ = apvts.getRawParameterValue("fb_q")->load();

    int delayInSamples = static_cast<int>((fbTime / 1000.0f) * currentSampleRate);
    if (delayInSamples >= delayBuffer.getNumSamples())
        delayInSamples = delayBuffer.getNumSamples() - 1;

    for (int ch = 0; ch < totalNumOutputChannels; ++ch)
    {
        fbFilters[ch].setCutoffFrequency(fbFreq);
        fbFilters[ch].setResonance(fbQ);

        auto* channelData = buffer.getWritePointer(ch);
        auto* fbWrite = feedbackBuffer.getWritePointer(ch);
        auto* delayData = delayBuffer.getReadPointer(ch);

        int tempReadPos = delayWritePosition[ch] - delayInSamples;
        if (tempReadPos < 0) tempReadPos += delayBuffer.getNumSamples();

        for (int i = 0; i < buffer.getNumSamples(); ++i)
        {
            float delayedSample = delayData[tempReadPos] * (fbAmount / 100.0f);

            fbWrite[i] = fbFilters[ch].processSample(0, delayedSample);

            tempReadPos++;
            if (tempReadPos >= delayBuffer.getNumSamples()) tempReadPos = 0;
        }
    }

    juce::dsp::AudioBlock<float> fbBlock(feedbackBuffer);
    juce::dsp::ProcessContextReplacing<float> fbContext(fbBlock);
    fbCompressor.process(fbContext);

    for (int ch = 0; ch < totalNumOutputChannels; ++ch)
    {
        buffer.addFrom(ch, 0, feedbackBuffer, ch, 0, buffer.getNumSamples());
    }

    multibandProcessor.setCrossoverFrequencies(lowMidCut, midHighCut);

    int typeIndex = static_cast<int>(apvts.getRawParameterValue("sat_type")->load());
    multibandProcessor.setSaturationType(typeIndex);
    multibandProcessor.setDrives(low, mid, high);
    multibandProcessor.process(buffer);

    for (int ch = 0; ch < totalNumOutputChannels; ++ch)
    {
        auto* channelData = buffer.getReadPointer(ch);
        auto* delayWriteData = delayBuffer.getWritePointer(ch);

        int tempWritePos = delayWritePosition[ch];

        for (int i = 0; i < buffer.getNumSamples(); ++i)
        {
            delayWriteData[tempWritePos] = channelData[i];

            tempWritePos++;
            if (tempWritePos >= delayBuffer.getNumSamples()) tempWritePos = 0;
        }

        delayWritePosition[ch] = tempWritePos;
    }

    float revAmount = apvts.getRawParameterValue("reverb")->load();

    juce::Reverb::Parameters currentReverbParams = outputReverb.getParameters();
    currentReverbParams.roomSize = apvts.getRawParameterValue("room_size")->load();
    currentReverbParams.wetLevel = revAmount;
    currentReverbParams.dryLevel = 1.0f - revAmount;

    outputReverb.setParameters(currentReverbParams);

    if (totalNumOutputChannels == 2)
    {
        outputReverb.processStereo(buffer.getWritePointer(0),
            buffer.getWritePointer(1),
            buffer.getNumSamples());
    }
    else if (totalNumOutputChannels == 1)
    {
        outputReverb.processMono(buffer.getWritePointer(0),
            buffer.getNumSamples());
    }

}

//==============================================================================
// 6. EDITOR AND STATE SAVING
bool MultiSaturatorAudioProcessor::hasEditor() const
{
    return true;
}

juce::AudioProcessorEditor* MultiSaturatorAudioProcessor::createEditor()
{
    return new multiSaturatorAudioProcessorEditor(*this);
}

void MultiSaturatorAudioProcessor::getStateInformation(juce::MemoryBlock& destData)
{
    auto state = apvts.copyState();
    std::unique_ptr<juce::XmlElement> xml(state.createXml());
    copyXmlToBinary(*xml, destData);
}

void MultiSaturatorAudioProcessor::setStateInformation(const void* data, int sizeInBytes)
{
    std::unique_ptr<juce::XmlElement> xmlState(getXmlFromBinary(data, sizeInBytes));
    if (xmlState.get() != nullptr)
        if (xmlState->hasTagName(apvts.state.getType()))
            apvts.replaceState(juce::ValueTree::fromXml(*xmlState));
}

//==============================================================================
// 7. THE ENTRY POINT
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new MultiSaturatorAudioProcessor();
}