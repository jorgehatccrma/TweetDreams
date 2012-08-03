// twtNodeSynth.ck
//
// The instrument for a single node/tweet
//
// Edit History:
//   Created by Luke Dahl  5/9/10

// This version is for N-channel sound

// the synth
public class twtNodeSynth2
{
    2 => int numChans;
    -1.0 + 1./numChans => float out1Loc;         // the pan location of the first speaker. speakers are assumed to proceed in order clockwise
 
    // these get controlled by the master performer
    10::ms => static dur tickTime;
    1.0 => static float masterTune;
    
    // static member variables (shared by all instances) ----------------
    [ "wavs/sine.aif",       "wavs/sineesque.aif", "wavs/squaresque1.aif", "wavs/sawesque1.aif",
      "wavs/tonenoise1.aif", "wavs/belly1.aif",    "wavs/beow1.aif",        "wavs/blip1.aif",
      "wavs/filtnois1.aif",  "wavs/kick1.aif",     "wavs/zap1.aif",         "wavs/dignois2.aif",
      "wavs/bell1.aif",  "wavs/suck2.aif" ] @=> static string wavNames[];
    wavNames.cap() => int numWavs;
    13 => static int suckWavNum;
  
    7 => static int modeSize;  // DO NOT CHANGE THIS!!! // ALL MODES MUST BE THE SAME LENGTH (modeSize)!!!
    [ [60,62,63,65,67,69,70], [60,61,63,65,67,68,70], [60,62,64,66,67,69,71], [60,62,64,65,67,69,70] ] @=> static int mode[][];      // this is the scale mode for notes //TODO: make this array 2D to support multiple modes
    // dorian                 phrygian                lydian                  mixolydian
    6 => static int numSeqSteps;
    999 => static int noNoteCode;                            // this 'note' means don't play
    
    // member variables -------------------------------------------------
    int noteSeq[numSeqSteps];        // this is the note sequence that gets played for this node
    0 => int isConnected;            // is the dac hooked up?
    0 => int numNotesPlaying;        // how many difft threads are trying to play this node?
    
    // these members are synthesis parameters
    int wavNum;                      // which wavetable to use
    int modeNum;                     // which mode to use
    float fltFrqRto;                 // a ratio between 0.1 and 8., or so.  Will set the cutoff as a ratio of fundamental
    float fltQ;
    int dcyTcks;                  // number of ticks that the envelope decays by
    int attTcks;                  // number of ticks that for the envelope to attack
    int stepTcks;                 // the time ticks between notes in a sequence
    float panLR;                  // pan level between -1 and +1. 0=center, neg=left, pos=right
    int sp1;                      // which speaker to hook dryLvlL to
    int sp2;                      // which speaker to hook dryLvlR to
    
    // audio processing chain 
    SndBuf wavSynth[numWavs]; 
    Gain gn => LPF flt => ADSR env => Pan2 panr;
    panr.left => Gain dryLvlL;    
    panr.right => Gain dryLvlR;    
    Gain dryOut[ numChans ];
    
    // env => Gain wetLvl;
    // Gain dryOutL;
    // Gain dryOutR;
    // Gain wetOut;
    
    // INITIALIZE this node
    // public void init( UGen dry_ugenL, UGen dry_ugenR, UGen wet_ugen  )
    // public void init( UGen dry0, UGen dry1, UGen dry2, UGen dry3, UGen dry4, UGen dry5, UGen dry6, UGen dry7  )
    public void init( Gain dry[] )
    {
        // load the wav files
        for( 0 => int i; i < numWavs; i++ ) 
        {
            wavNames[i] => wavSynth[i].read;
            wavSynth[i].samples() => wavSynth[i].pos;  
            1 => wavSynth[i].interp;     // 0 is drop sample, 1 is linear, 2 is sync interp 
            //2 => wavSynth[i].interp;     // 0 is drop sample, 1 is linear, 2 is sync interp 
        }
        
        // hook up the ugens     
        for( 0 => int i; i < numChans; i++ ) 
        {
            dryOut[i] => dry[i];
        }
                        
        0.6 => dryLvlL.gain => dryLvlR.gain;      
    }

    
    
    // public methods ---------------------------------------------------
    public void play( int hopLvl, float revs, int seq[], int wav_num, int mode_num, float flt_frq_ratio, float flt_Q, int dcy_ticks, int att_ticks, int note_ticks, float pan_in)
    {
        //  <<< "playing ", "" >>>;
        
        // set sequence
        for( 0 => int i; i < numSeqSteps; i++ )
        {
            seq[i] => noteSeq[i];
        }
        
        // set note & timing params:
        wav_num => wavNum;
        mode_num => modeNum;
        dcy_ticks => dcyTcks;
        att_ticks => attTcks;
        note_ticks => stepTcks;
        
        // initialize synth stuff     
        pan_in => panLR;
        flt_frq_ratio => fltFrqRto;
        flt_Q => fltQ;
        env.set( attTcks*tickTime, tickTime, 0.9, dcyTcks*tickTime );
        env.keyOff();
        fltQ => flt.Q;
        
        // now trigger it:
        if( revs )
            triggerSuck( hopLvl );
        else
            trigger( hopLvl );

    }
    
     
    public void setNoteSeq( int seq[] )
    {
        for( 0 => int i; i < numSeqSteps; i++ )
        {
            seq[i] => noteSeq[i];
        }
    }
    
    public void setNoteSeqAtIndex( int val, int ind )
    {
        val => noteSeq[ ind ];
    }
    
    public int getNoteSeqAtIndex( int ind )
    {
        return noteSeq[ ind ];
    }
    
    // calculates pans and which output to hook up to
    fun void calcPan()
    {
        // panLR is between -1 and +1. 0=center, neg=left, pos=right
        // out1Loc is the location of the first speaker. speakers are assumed to proceed in order clockwise
        Math.fmod( panLR, 2.) - out1Loc => float pan2;           // rotate so 0=loc1
        if( pan2 < 0)
            pan2 + 2. => pan2;
        
        // find which pair of speakers to connect to
        (Math.floor( pan2 *numChans / 2.))$int => int pair;
        if( pair < 0 )
            pair + numChans => pair;   
        pair => sp1;
        (pair + 1) % numChans => sp2;
        
        pan2 - pair*2.0/numChans => float pan3;               // rotate so 0=speaker1   
        Math.fmod(pan3*numChans/2., numChans) => float pan4;  // scale to [0,1]
        
        pan4*2. - 1. => float pan5;                           // scale to [-1,1]
        pan5 => panr.pan;
    }


    // makes a node play its note sequence
    public void trigger( int hopLevel )
    {
        0. => float dbdown;
        if( hopLevel > 0)
            5 + 1.5*(hopLevel-1) => dbdown;    // first hop is -4db, themn -2db more for each subsequent hop
        
        if( dbdown > 70 )
            return;             // if we are already super quiet, no need to play
 
        // connect
        if( isConnected ) {
            <<< "twtNodeSynth2 WARNING: triggering a synth that's already playing! *&*&*&*&*&*&*&*&*&*&*", "" >>>;
            return;
        }
        
        // connect wav synth!
        //if (isConnected == 0)
        1 => isConnected;
        
        0.6 => dryLvlL.gain => dryLvlR.gain;    
        
        // calculate pan and hookup
        calcPan();
        dryLvlL => dryOut[sp1];
        dryLvlR => dryOut[sp2];
        
        // hookup appropriate wavSynth
        wavSynth[wavNum] => gn;
        
        //<<< "connecting ", wavNames[ wavNum ] >>>;  // DEBUG
        // numNotesPlaying++;  do I still need this? - LD 8/18/10

        // set level quieter for later hops
        Std.dbtorms( 100 - dbdown ) => env.gain;
        
        for( 0 => int i; i < numSeqSteps; i++)
        {
            noteToMidi( noteSeq[i] ) => int midiNote; 
            if (midiNote != noNoteCode ) 
            {
                Math.pow(2, (midiNote - 60)/12.0 ) => float tempF;
                masterTune *=> tempF => wavSynth[wavNum].rate;
                Std.mtof(midiNote) * fltFrqRto * Math.pow(0.7,hopLevel) => tempF;
                //<<< "filt freq", tempF >>>;   //DEBUG
                if( tempF > 20000. )          // TODO: make this depend on sampling rate
                    20000. => tempF;
                tempF => flt.freq;  
                
                0 => wavSynth[wavNum].pos;            
                env.keyOn();
                attTcks * tickTime => now;
                env.keyOff();
                (stepTcks - attTcks) * tickTime => now;           
            }
            else
                stepTcks * tickTime => now;
        }
        
        // let env decay and disconnect
        5*dcyTcks*tickTime => now;
        
        //if( isConnected && (numNotesPlaying == 1) )
        //{
        dryLvlL =< dryOut[sp1];
        dryLvlR =< dryOut[sp2];
        
        //dryLvlL =< dryOutL;
        //dryLvlR =< dryOutR;
        //wetLvl =< wetOut;
        wavSynth[wavNum] =< gn;
        0 => isConnected;
        //}
        // numNotesPlaying--;      
    }
    
    
    // make the giant sucking sound
    public void triggerSuck( int hopLevel )
    {   
        Std.dbtorms( 100 ) => env.gain;
        0.1 => dryLvlL.gain => dryLvlR.gain;
        // 0.05 => wetLvl.gain;
        suckWavNum => wavNum;
        
        // connect wav synth!
        1 => isConnected;
        
        calcPan();
        dryLvlL => dryOut[sp1];
        dryLvlR => dryOut[sp2];
        
        //dryLvlL => dryOutL;
        //dryLvlR => dryOutR;
        //wetLvl => wetOut;
        wavSynth[wavNum] => gn;
        
        //find the last note
        0 => int lastNoteInd;
        0 => int lastMidiNote;
        for( 0 => int i; i < numSeqSteps; i++) {
            noteToMidi( noteSeq[i] ) => int midiNote;
            if (midiNote != noNoteCode ) {
                i => lastNoteInd;
                midiNote => lastMidiNote;
            }
        }
        
        // wait the correct amount of time
//        stepTcks * (lastNoteInd+2) * tickTime => now;
//        stepTcks * (lastNoteInd+18) * tickTime => now;
        12 * (lastNoteInd+20) * tickTime => now;
            
        //trigger note
        Math.pow(2, (lastMidiNote - 60)/12.0 ) => float tempF;
        masterTune * tempF => float tempR;
        tempR => wavSynth[wavNum].rate;
        Std.mtof(lastMidiNote) * fltFrqRto * Math.pow(0.9,hopLevel) => tempF;
        if( tempF > 20000. ) 20000. => tempF;
        tempF* 0.4 => flt.freq;
        
        env.set( 1*stepTcks*tickTime, tickTime, 0.9, 1*tickTime );               
        0 => wavSynth[wavNum].pos; 
        env.keyOn();
        20*stepTcks*tickTime => now;
        env.keyOff();
        2*stepTcks*tickTime => now;
        
        // let env decay and disconnect
        5*dcyTcks*tickTime => now;
        
        
        dryLvlL =< dryOut[sp1];
        dryLvlR =< dryOut[sp2];
        
        //dryLvlL =< dryOutL;
        //dryLvlR =< dryOutR;
        // wetLvl =< wetOut;
        wavSynth[wavNum] =< gn;
        0 => isConnected;
     }

    
        
    // private methods ---------------------------------------------------
    
    // from a note value create a midi note, given the current mode
    fun int noteToMidi( int note )
    {
        int returnVal;
        
        if( note == noNoteCode ) {
            note => returnVal;
        }
        else if( note >=modeSize ) {
            note % modeSize => int i;
            (note - i) / modeSize => int n;
            n*12 + mode[modeNum][ i ] => returnVal;
        }
        else if( note < 0 ) {
            -note % modeSize => int i;
            (-note - i) / modeSize => int n;
            if( i == 0)
                mode[modeNum][ 0 ] - n*12 => returnVal;
            else
                mode[modeNum][ (n+1)*modeSize +note ] - (n+1)*12 => returnVal;
        }
        else {
            mode[modeNum][ note ] => returnVal;
        }
        return returnVal;
    }
}




