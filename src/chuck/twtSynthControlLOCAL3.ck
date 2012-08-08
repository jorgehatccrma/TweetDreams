// twtSynthControlLOCAL.ck
//
// Recieves OSC messages from python, and controls synths.
//
// Edit History:
//   Created by Luke Dahl  5/3/10

// This version is for N-channel sound

// some globals -------------------------------------------------
0 => int twtSynthCtlLocalDebug;         // turn on/off debug messages
0 => int twtSynthCtlLocalDebug2;        // turn on/off debug messages
2 => int gNumChans;                     // number of output channels
1 => int gPlayLocal;                    // flag to play local sounds
//2 => int dacOffset;                     // which dac output to start on
0 => int dacOffset;                     // which dac output to start on


//50 => int gNumSynths;                 // number of synth nodes
100 => int gNumSynths;                  // number of synth nodes
twtNodeSynth2 gSynthArray[gNumSynths];
0 => int gLastPlayedSynth;
100 => int numEchoStreams;

// setup Osc receive ------------------------------------------
OscRecv osc_in;
8889 => int in_port => osc_in.port;
osc_in.listen();
osc_in.event( "/twt/newLocalNode, s s i i i f f i i i i i i i i i f" ) @=> OscEvent newNodeEvent;
osc_in.event( "/twt/triggerLocalNode", "i s f i" ) @=> OscEvent triggerNodeEvent;
osc_in.event( "/twt/setSynthStatics", "i i f") @=> OscEvent staticsEvent;
osc_in.event( "/twt/setDryLvl", "f") @=> OscEvent dryLvlEvent;


// twtNodeDataLocal class --------------------------------------
public class twtNodeDataLocal
{
    // statics ----------------------------------------------------------
    6 => static int numSeqSteps;      // duplicate data... also in twtNodeSynth
    999 => static int noNoteCode;     // duplicate data... also in twtNodeSynth
    12 => static int localWavNum;     // the index for the wav for local tweets
    
    // public members ---------------------------------------------------
    string msgStr;
    // int clientNum;                   // which client is playing this node... doesn't matter!  the next one!
    string nodeID;
    int isLocal;                      
    
    int noteSeq[numSeqSteps];
    int wavNum;                      // which wavetable to use
    int modeNum;                     // which mode to use
    float fltFrqRto;                 // a ratio between 0.1 and 8., or so.  Will set the cutoff as a ratio of fundamental
    float fltQ;
    int dcyTcks;                     // number of ticks that the envelope decays by
    int attTcks;                     // number of ticks that for the envelope to attack
    int stepTcks;                    // number of ticks in a note
    float pan;
    
    // public methods ---------------------------------------------------
    
    // send message to synth to trigger
    public void trigger( int hopLvl )
    {    
        gLastPlayedSynth++; if( gLastPlayedSynth >= gNumSynths - 1) 0 => gLastPlayedSynth;

        if( twtSynthCtlLocalDebug )
            <<< "[sound client] twtNodeLocalData: triggering synth ", gLastPlayedSynth >>>;
        
        //gSynthArray[gLastPlayedSynth].play( hopLvl, noteSeq, wavNum, modeNum, fltFrqRto, fltQ, dcyTcks, attTcks, stepTcks, pan);
        spork ~ gSynthArray[gLastPlayedSynth].play( hopLvl, 0, noteSeq, wavNum, modeNum, fltFrqRto, fltQ, dcyTcks, attTcks, stepTcks, pan);
        
        // play reverse sucking sound
        if( hopLvl == 0 ){
             gLastPlayedSynth++; if( gLastPlayedSynth >= gNumSynths - 1) 0 => gLastPlayedSynth;
             spork ~ gSynthArray[gLastPlayedSynth].play( hopLvl, 1, noteSeq, wavNum, modeNum, fltFrqRto, fltQ, dcyTcks, attTcks, stepTcks, pan);
        }
        
        // add sound for local tweet.
        if( isLocal && (hopLvl == 0 ) && gPlayLocal)
        {
            gLastPlayedSynth++; if( gLastPlayedSynth >= gNumSynths - 1) 0 => gLastPlayedSynth;
            if( twtSynthCtlLocalDebug )
                <<< "[sound client] twtNodeLocalData: triggering Local synth ", gLastPlayedSynth >>>;
            spork ~ gSynthArray[gLastPlayedSynth].play( hopLvl, 0, noteSeq, localWavNum, modeNum, fltFrqRto*0.15, fltQ, 40, 1, stepTcks, pan);           
        }
    }
    
    // initialize node:
    public void init( string id_str, int wav_num, int mode_num, float flt_frq_ratio, float flt_Q, int dcy_ticks, int att_ticks, int note_ticks, float pan_in)
    {
        // set member vars
        id_str => nodeID;
        wav_num => wavNum;
        mode_num => modeNum;
        Std.rand2f(-1,1) => pan;
        pan_in => pan;
        flt_frq_ratio => fltFrqRto;
        flt_Q => fltQ;
        dcy_ticks => dcyTcks;
        att_ticks => attTcks;
        note_ticks => stepTcks;        
    }
    
    // set the note sequence:
    public void setNoteSeq( int seq[] ) 
    {
        for( 0 => int i; i < numSeqSteps; i++ ) {
            seq[i] => noteSeq[i];
        }
    }
    
    // set a specific note in the sequence:
    public void setNoteSeqAtIndex( int val, int ind )
    {
        val => noteSeq[ ind ];
    }    
}




// audio processing chain -------------------------------------
twtNodeDataLocal synthDataArray[1];

Gain inputs[ gNumChans ];
Gain dryMix[ gNumChans ];
PoleZero DCB[ gNumChans ];
JCRev rev[ gNumChans ];
Gain revMix[ gNumChans ];

// Gain dryMixL => PoleZero DCB1L => dac.left;
// Gain dryMixR => PoleZero DCB1R => dac.right;
// Gain revMix => PoleZero DCB2 => JCRev rev => dac;
// DCB1L.blockZero( 0.999 );
// DCB1R.blockZero( 0.999 );
// DCB2.blockZero( 0.999 );

0.999 => float dcbl;      // coeff for DC blockers
0.2 => float wetgn;     // default gain to reverbs
for (0 => int i; i < gNumChans; i++ )
{
    // <<< "[sound client] test1","--------">>>;
    //inputs[i*2]   => dryMix[i*2]   => DCB[i*2]   => dac.chan(i*2);
    //inputs[i*2+1] => dryMix[i*2+1] => DCB[i*2+1] => dac.chan(i*2+1);
    
    //inputs[i*2] => revMix[i];
    //inputs[i*2+1] => revMix[i];
    //revMix[i] => DCB2[i] => rev[i];
    
    //<<< "[sound client] test2","--------">>>;
    //<<<"[sound client]  channels?", rev[i].channels() >>>;
    //rev[i].chan(0) => dac.chan(i*2);
    //rev[i].chan(1) => dac.chan(i*2+1);
    
    //inputs[i] => DCB[i] => dryMix[i] => dac.chan(i);
    // DCB[i] => revMix[i] => rev[i] => dac.chan(i);
    inputs[i] => dryMix[i] => dac.chan(i+dacOffset);
    inputs[i] => revMix[i] => rev[i] => dac.chan(i+dacOffset);
    wetgn => revMix[i].gain;
    DCB[i].blockZero( dcbl );
    
    //DCB[i*2].blockZero( dcbl );
    //DCB[i*2+1].blockZero( dcbl );
    //DCB2[i].blockZero( dcbl );
}


// pass ugens to synths
for( 0 => int i; i < gNumSynths; i++){
    // gSynthArray[i].init( dryMixL, dryMixR, revMix );
    //gSynthArray[i].init( inputs[0],  inputs[1], inputs[2], inputs[3], inputs[4], inputs[5], inputs[6], inputs[7] );
    gSynthArray[i].init( inputs );
}

// spork listeners --------------------------------------------
<<< "[sound client] starting twtSynthControlLOCAL3.ck", "" >>>;
spork ~ newLocalNodeListener();
spork ~ triggerLocalNodeListener();
spork ~ staticNodeListener();
spork ~ dryLvlListener();
     
// some globals
0 => int wavNum;
0 => int modeNum;
6. => float fltR;
1. => float fltQ; 
1 => int dcy;
20 => int att;
20 => int stp;


// make time --------------------------------------------------
while( 1 )
{
    1::second => now;
}

// define useful functions ------------------------------------

// define processes -------------------------------------------


// processes newNode messages
fun void newLocalNodeListener()
{
    while( 1 )
    {
        newNodeEvent => now;
        while( newNodeEvent.nextMsg() )
        {
            int dummy[twtNodeDataLocal.numSeqSteps];
                
            newNodeEvent.getString() => string nodeID;      // nodeID
            newNodeEvent.getString() => string msgString;   // the tweet
            newNodeEvent.getInt() => wavNum;                // wavetable number
            newNodeEvent.getInt() => modeNum;               // mode number
            newNodeEvent.getInt() => int isLoc;             // is local
            newNodeEvent.getFloat() => fltR;                // filter frequency ratio
            newNodeEvent.getFloat() => fltQ;                // filter Q
            newNodeEvent.getInt() => dcy;                   // ticks in envelope decay
            newNodeEvent.getInt() => att;                   // ticks in envelope attack
            newNodeEvent.getInt() => stp;                   // ticks for each note 
            newNodeEvent.getInt() => dummy[0];              // note sequence
            newNodeEvent.getInt() => dummy[1];              // note sequence
            newNodeEvent.getInt() => dummy[2];              // note sequence
            newNodeEvent.getInt() => dummy[3];              // note sequence
            newNodeEvent.getInt() => dummy[4];              // note sequence
            newNodeEvent.getInt() => dummy[5];              // note sequence
            newNodeEvent.getFloat() => float panTemp;                 // LR pan
            
            
            if( twtSynthCtlLocalDebug )
                <<< "[sound client]      twtSynthControlLOCAL3 new node: ", nodeID, " ", msgString >>>;   // DEBUG
            if( twtSynthCtlLocalDebug2 )
                <<< "[sound client]      twtSynthControlLOCAL3 new node: ", nodeID >>>;   // DEBUG
            
            if( synthDataArray[nodeID] == NULL )
            {
                // initialize new node
                twtNodeDataLocal temp_node @=> synthDataArray[ nodeID ];
            } 
            else
            {
                <<<"[sound client] twtSynthControlLOCAL: Warning: Received newNode message for preexisting node","">>>;
            }
            synthDataArray[ nodeID ].init( nodeID, wavNum, modeNum, fltR, fltQ, dcy, att, stp, panTemp);           
            synthDataArray[ nodeID ].setNoteSeq( dummy );
            isLoc => synthDataArray[ nodeID ].isLocal;   
        }
    }
}

// listens for messages for changing synth statics (currently not using this, I think! - LD)
fun void staticNodeListener()
{
    // TODO:  these changes don't yet make their way down to the synth.... need to fix
    while( 1 )
    {
        staticsEvent => now;
        while( staticsEvent.nextMsg() )
        {
            /// staticsEvent.getInt() => twtNodeDataLocal.masterTune;
            // staticsEvent.getFloat()*1::ms => twtNodeDataLocal.tickTime;
            staticsEvent.getInt() => int msg;
            staticsEvent.getInt() => int msgInt;
            staticsEvent.getFloat() => float msgFlt;
            
            if( msg == 1 )
                msgInt => gPlayLocal;

        }
    }
}

// listens for messages for changing the gain of the dy signal
fun void dryLvlListener()
{
    while( 1 )
    {
        dryLvlEvent => now;
        while( dryLvlEvent.nextMsg() )
        {
            dryLvlEvent.getFloat() => float dryLvl;
            
            for (0 => int i; i < gNumChans; i++ )
            {
                dryLvl =>dryMix[i].gain;
            }
            
            //dryLvl => dryMixL.gain;
            //dryLvl => dryMixR.gain;
            
            if( twtSynthCtlLocalDebug )
            <<< "[sound client]      LOCAL: dryLvl message received:", dryLvl >>>;
        }
    }
}

// processes triggerNode messages
fun void triggerLocalNodeListener()
{
while( 1 )
{
    triggerNodeEvent => now;
    while( triggerNodeEvent.nextMsg() )
    {
        triggerNodeEvent.getInt() => int echoID;
        triggerNodeEvent.getString() => string nodeID;
        triggerNodeEvent.getFloat() => float delayMsec;
        triggerNodeEvent.getInt() => int hopLevel;
        if( twtSynthCtlLocalDebug )
          <<< "[sound client]      LOCAL: triggerNode message received. echoID:", echoID, " nodeID:", nodeID, " time:", delayMsec, " hopLevel:", hopLevel  >>>;
        if( twtSynthCtlLocalDebug2 )
          <<< "[sound client]      twtSynthControl2: triggerNode message received, node:", nodeID, " hopLevel:", hopLevel  >>>;
        
        // error handling: if we have not gotten a newNode ID for this one... make one up for now
        if( synthDataArray[nodeID] == NULL )
        {
            if( twtSynthCtlLocalDebug )
                <<<"[sound client]      LOCAL: WARNING: trigger received before newNode msg ",nodeID >>>;
            
            // initialize new node
            twtNodeDataLocal temp_node @=> synthDataArray[ nodeID ];
            
            // init( id, wav_num, mode_num, flt_frq_ratio, float flt_Q, decay_ticks, attack_ticks, note_ticks )
            synthDataArray[ nodeID ].init( nodeID, wavNum, modeNum, fltR, fltQ, dcy, att, stp, Std.rand2f(-0.3, -.3) );           
            twtNodeDataLocal.noNoteCode => int nonote;  
            [0, -1, nonote, nonote, 4, nonote] @=> int dummy[];           
            synthDataArray[ nodeID ].setNoteSeq( dummy );   
        }
        
        synthDataArray[nodeID].trigger( hopLevel );
        //spork ~ synthDataArray[nodeID].trigger( hopLevel );
        
        //}      
    }
}
}


