# P_ToBI intonational transcriber
A Praat script that transcribes European Portuguese intonation using P_ToBI system. Check the [2024 Speech Prosody poster](2024_poster_P_ToBI_SP.pdf).


A rule-based Praat script designed to generate P-ToBI labels based on the pitch contour given a tier with by-syllable intervals and stress marks. 
The system was trained on a 96-sentence corpus comprising all Nuclear Pitch Accents (NPA) and Boundary Tones (BT) in European Portuguese (EP). Evaluation was conducted on a separate corpus of 146 sentences showing a success rate of 73.8% (k=0.6) for NPA and 78.7% for BT (k=0.6). 

The qualitative analysis of errors, excluding those stemming from the pitch tracking algorithm, exposes challenges in accurately identifying falling NPAs, particularly instances of L*, H*+L, and H+L* followed by a low BT.

>[!TIP]
>Please cite as: Elvira-García, Wendy; Marisa Cruz, Marina Vigário, Sónia Frota. (2024). An automatic prosodic transcriber for the P-ToBI system. Speech Prosody 2024. Leiden.
