export type SoundOption = 'A' | 'B' | 'C' | 'D';

class SoundNotificationService {
  private isEnabled: boolean = true;
  private volume: number = 70;
  private soundOption: SoundOption = 'D';
  private audioContext: AudioContext | null = null;
  private isAlarmPlaying: boolean = false;
  private alarmNodes: OscillatorNode[] = [];
  private isUnlocked: boolean = false;
  private keepAliveInterval: ReturnType<typeof setInterval> | null = null;

  constructor() {
    console.log('🔊 SoundNotificationService initialized');
    this.setupAutoUnlock();
  }

  /**
   * Mobile browsers require a user gesture to unlock AudioContext.
   * This listens for the first tap/click and unlocks audio playback.
   */
  private setupAutoUnlock(): void {
    if (typeof window === 'undefined') return;

    const unlock = async () => {
      try {
        const ctx = await this.ensureAudioContext();
        const buffer = ctx.createBuffer(1, 1, 22050);
        const source = ctx.createBufferSource();
        source.buffer = buffer;
        source.connect(ctx.destination);
        source.start(0);
        this.isUnlocked = true;
        console.log('🔓 AudioContext unlocked by user gesture');

        this.startKeepAlive();
      } catch (e) {
        console.warn('⚠️ AudioContext unlock failed:', e);
      }

      document.removeEventListener('click', unlock, true);
      document.removeEventListener('touchstart', unlock, true);
      document.removeEventListener('touchend', unlock, true);
    };

    document.addEventListener('click', unlock, true);
    document.addEventListener('touchstart', unlock, true);
    document.addEventListener('touchend', unlock, true);
  }

  /**
   * Periodically play a silent buffer to prevent the browser from
   * suspending the AudioContext during long idle periods.
   */
  private startKeepAlive(): void {
    if (this.keepAliveInterval) return;
    this.keepAliveInterval = setInterval(async () => {
      try {
        if (this.audioContext && this.audioContext.state === 'running') {
          const buffer = this.audioContext.createBuffer(1, 1, 22050);
          const source = this.audioContext.createBufferSource();
          source.buffer = buffer;
          source.connect(this.audioContext.destination);
          source.start(0);
        }
      } catch { /* ignore */ }
    }, 25000);
  }

  private triggerVibration(pattern: number[] = [200, 100, 200]): void {
    try {
      if ('vibrate' in navigator) {
        navigator.vibrate(pattern);
      }
    } catch { /* vibration not supported */ }
  }

  public updateSettings(isEnabled: boolean, volume: number, soundOption: SoundOption = 'B') {
    this.isEnabled = isEnabled;
    this.volume = volume;
    this.soundOption = soundOption;
    console.log(`🔊 Sound settings updated: enabled=${isEnabled}, volume=${volume}, option=${soundOption}`);
  }

  public async playNotificationSound(): Promise<void> {
    console.log(`🔊 Attempting to play sound: enabled=${this.isEnabled}, volume=${this.volume}`);
    
    if (!this.isEnabled) {
      console.log('🔇 Sound notifications are disabled');
      return;
    }

    this.triggerVibration([200, 100, 200]);

    try {
      await this.playWebAudioBeep();
    } catch (error) {
      console.warn('⚠️ Web Audio failed, trying HTML5 Audio fallback:', error);
      await this.playFallbackAudio();
    }
  }

  /**
   * Fallback: use HTML5 Audio with a data URI tone.
   * Works on some devices where AudioContext is blocked.
   */
  private async playFallbackAudio(): Promise<void> {
    try {
      const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdH2JkZqTi4F2aGBbX2x6iJOcm5KHfHBkXl5ka3mGkJmYkYR4bGFdYGdyf4uVm5eSiHxwZF1eZGx5hpCZmJGFeW1hXmBncn+LlZuXkoh8cGRdXmRseYaQmZiRhXltYV5gZ3J/i5Wbl5KIfHBkXV5kbHmGkJmYkYV5bWFeYGdyf4uVm5eSiHxwZF1eZGx5hpCZmJGFeW1hXmBncn+LlZuXkoh8cGRdXg==');
      audio.volume = Math.min(this.volume / 100, 1);
      await audio.play();
      console.log('✅ Fallback HTML5 Audio played');
    } catch (error) {
      console.error('❌ HTML5 Audio fallback also failed:', error);
    }
  }

  private async ensureAudioContext(): Promise<AudioContext> {
    if (!this.audioContext || this.audioContext.state === 'closed') {
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    }

    if (this.audioContext.state === 'suspended') {
      await this.audioContext.resume();
      console.log('🔊 Audio context resumed');
    }

    return this.audioContext;
  }

  private async playWebAudioBeep(): Promise<void> {
    try {
      const audioContext = await this.ensureAudioContext();

      // Generate beep sound
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      // Set frequency and type for a pleasant notification sound
      oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
      oscillator.type = 'sine';
      
      // Set volume based on settings (0.3 is max to avoid distortion)
      const normalizedVolume = (this.volume / 100) * 0.3;
      
      // Create envelope for smooth sound
      gainNode.gain.setValueAtTime(0, audioContext.currentTime);
      gainNode.gain.linearRampToValueAtTime(normalizedVolume, audioContext.currentTime + 0.01);
      gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
      
      // Play the sound
      oscillator.start(audioContext.currentTime);
      oscillator.stop(audioContext.currentTime + 0.3);
      
      console.log('✅ Notification sound played successfully');
    } catch (error) {
      console.error('❌ Web Audio API failed:', error);
      throw error;
    }
  }

  // Option A: Multi-tone chime (2-3 notes, ~1.5 seconds)
  public async playOptionA_MultiToneChime(): Promise<void> {
    try {
      const audioContext = await this.ensureAudioContext();
      const normalizedVolume = (this.volume / 100) * 0.6; // Louder: 60% max
      const startTime = audioContext.currentTime;

      // First note: C5 (523.25 Hz) - 0.4s
      const note1 = audioContext.createOscillator();
      const gain1 = audioContext.createGain();
      note1.connect(gain1);
      gain1.connect(audioContext.destination);
      note1.frequency.setValueAtTime(523.25, startTime);
      note1.type = 'sine';
      gain1.gain.setValueAtTime(0, startTime);
      gain1.gain.linearRampToValueAtTime(normalizedVolume, startTime + 0.05);
      gain1.gain.exponentialRampToValueAtTime(0.01, startTime + 0.4);
      note1.start(startTime);
      note1.stop(startTime + 0.4);

      // Second note: E5 (659.25 Hz) - 0.4s, starts at 0.3s
      const note2 = audioContext.createOscillator();
      const gain2 = audioContext.createGain();
      note2.connect(gain2);
      gain2.connect(audioContext.destination);
      note2.frequency.setValueAtTime(659.25, startTime + 0.3);
      note2.type = 'sine';
      gain2.gain.setValueAtTime(0, startTime + 0.3);
      gain2.gain.linearRampToValueAtTime(normalizedVolume, startTime + 0.35);
      gain2.gain.exponentialRampToValueAtTime(0.01, startTime + 0.7);
      note2.start(startTime + 0.3);
      note2.stop(startTime + 0.7);

      // Third note: G5 (783.99 Hz) - 0.4s, starts at 0.6s
      const note3 = audioContext.createOscillator();
      const gain3 = audioContext.createGain();
      note3.connect(gain3);
      gain3.connect(audioContext.destination);
      note3.frequency.setValueAtTime(783.99, startTime + 0.6);
      note3.type = 'sine';
      gain3.gain.setValueAtTime(0, startTime + 0.6);
      gain3.gain.linearRampToValueAtTime(normalizedVolume, startTime + 0.65);
      gain3.gain.exponentialRampToValueAtTime(0.01, startTime + 1.0);
      note3.start(startTime + 0.6);
      note3.stop(startTime + 1.0);

      // Wait for all notes to finish
      await new Promise(resolve => setTimeout(resolve, 1100));
      console.log('✅ Option A: Multi-tone chime played');
    } catch (error) {
      console.error('❌ Option A failed:', error);
      throw error;
    }
  }

  // Option B: Classic notification sound (like iOS/Android) - ~1.2 seconds
  public async playOptionB_ClassicNotification(): Promise<void> {
    try {
      const audioContext = await this.ensureAudioContext();
      const normalizedVolume = (this.volume / 100) * 0.7; // Louder: 70% max
      const startTime = audioContext.currentTime;

      // Create a more complex waveform for classic notification sound
      // Using square wave with harmonics for a richer sound
      const oscillator = audioContext.createOscillator();
      const gainNode = audioContext.createGain();
      
      oscillator.connect(gainNode);
      gainNode.connect(audioContext.destination);
      
      // Classic notification: starts at 800Hz, sweeps to 1000Hz
      oscillator.frequency.setValueAtTime(800, startTime);
      oscillator.frequency.linearRampToValueAtTime(1000, startTime + 0.15);
      oscillator.frequency.setValueAtTime(800, startTime + 0.3);
      oscillator.frequency.linearRampToValueAtTime(1000, startTime + 0.45);
      oscillator.type = 'square'; // Square wave for more presence
      
      // Envelope: two pulses
      gainNode.gain.setValueAtTime(0, startTime);
      gainNode.gain.linearRampToValueAtTime(normalizedVolume, startTime + 0.02);
      gainNode.gain.setValueAtTime(normalizedVolume, startTime + 0.28);
      gainNode.gain.linearRampToValueAtTime(0, startTime + 0.32);
      gainNode.gain.setValueAtTime(0, startTime + 0.47);
      gainNode.gain.linearRampToValueAtTime(normalizedVolume, startTime + 0.49);
      gainNode.gain.setValueAtTime(normalizedVolume, startTime + 0.75);
      gainNode.gain.exponentialRampToValueAtTime(0.01, startTime + 1.2);
      
      oscillator.start(startTime);
      oscillator.stop(startTime + 1.2);

      await new Promise(resolve => setTimeout(resolve, 1300));
      console.log('✅ Option B: Classic notification played');
    } catch (error) {
      console.error('❌ Option B failed:', error);
      throw error;
    }
  }

  // Option C: Custom pattern (double beep with pause) - ~1.8 seconds
  public async playOptionC_DoubleBeepPattern(): Promise<void> {
    try {
      const audioContext = await this.ensureAudioContext();
      const normalizedVolume = (this.volume / 100) * 0.65; // Louder: 65% max
      const startTime = audioContext.currentTime;

      // First beep: 1000Hz for 0.3s
      const beep1 = audioContext.createOscillator();
      const gain1 = audioContext.createGain();
      beep1.connect(gain1);
      gain1.connect(audioContext.destination);
      beep1.frequency.setValueAtTime(1000, startTime);
      beep1.type = 'sine';
      gain1.gain.setValueAtTime(0, startTime);
      gain1.gain.linearRampToValueAtTime(normalizedVolume, startTime + 0.02);
      gain1.gain.setValueAtTime(normalizedVolume, startTime + 0.28);
      gain1.gain.exponentialRampToValueAtTime(0.01, startTime + 0.3);
      beep1.start(startTime);
      beep1.stop(startTime + 0.3);

      // Pause: 0.3s silence

      // Second beep: 1200Hz for 0.4s (slightly higher pitch, longer)
      const beep2 = audioContext.createOscillator();
      const gain2 = audioContext.createGain();
      beep2.connect(gain2);
      gain2.connect(audioContext.destination);
      beep2.frequency.setValueAtTime(1200, startTime + 0.6);
      beep2.type = 'sine';
      gain2.gain.setValueAtTime(0, startTime + 0.6);
      gain2.gain.linearRampToValueAtTime(normalizedVolume, startTime + 0.62);
      gain2.gain.setValueAtTime(normalizedVolume, startTime + 0.98);
      gain2.gain.exponentialRampToValueAtTime(0.01, startTime + 1.0);
      beep2.start(startTime + 0.6);
      beep2.stop(startTime + 1.0);

      // Final longer beep: 800Hz for 0.5s (lower, more attention-grabbing)
      const beep3 = audioContext.createOscillator();
      const gain3 = audioContext.createGain();
      beep3.connect(gain3);
      gain3.connect(audioContext.destination);
      beep3.frequency.setValueAtTime(800, startTime + 1.3);
      beep3.type = 'sine';
      gain3.gain.setValueAtTime(0, startTime + 1.3);
      gain3.gain.linearRampToValueAtTime(normalizedVolume, startTime + 1.32);
      gain3.gain.setValueAtTime(normalizedVolume, startTime + 1.78);
      gain3.gain.exponentialRampToValueAtTime(0.01, startTime + 1.8);
      beep3.start(startTime + 1.3);
      beep3.stop(startTime + 1.8);

      await new Promise(resolve => setTimeout(resolve, 1900));
      console.log('✅ Option C: Double beep pattern played');
    } catch (error) {
      console.error('❌ Option C failed:', error);
      throw error;
    }
  }

  // Option D: Urgent Order Alarm - Loud, persistent ringing (~8 seconds)
  // Simulates a restaurant order bell / phone ringing that's impossible to miss
  public async playOptionD_UrgentOrderAlarm(): Promise<void> {
    // Prevent overlapping alarms
    if (this.isAlarmPlaying) {
      console.log('🔔 Alarm already playing, skipping');
      return;
    }

    try {
      this.isAlarmPlaying = true;
      this.alarmNodes = [];
      const audioContext = await this.ensureAudioContext();
      const normalizedVolume = (this.volume / 100) * 0.95; // Very loud: 95% max
      const startTime = audioContext.currentTime;

      // === Ring pattern: 4 cycles of "RING-RING" like a phone ===
      // Each cycle: two short bursts at alternating frequencies + gap
      const ringCycles = 4;
      const burstDuration = 0.35;  // Each ring burst
      const gapBetweenBursts = 0.15; // Gap within a ring pair
      const gapBetweenCycles = 0.45; // Gap between ring-ring pairs
      const cycleDuration = (burstDuration * 2) + gapBetweenBursts + gapBetweenCycles;

      for (let cycle = 0; cycle < ringCycles; cycle++) {
        const cycleStart = startTime + (cycle * cycleDuration);

        // --- First ring burst (higher pitch) ---
        const ring1 = audioContext.createOscillator();
        const gain1 = audioContext.createGain();
        const ring1b = audioContext.createOscillator(); // Harmonic for richer sound
        const gain1b = audioContext.createGain();

        ring1.connect(gain1);
        gain1.connect(audioContext.destination);
        ring1b.connect(gain1b);
        gain1b.connect(audioContext.destination);

        // Main tone: 900 Hz (phone ring frequency)
        ring1.frequency.setValueAtTime(900, cycleStart);
        ring1.type = 'square';
        // Harmonic overtone: 1400 Hz for that metallic ring quality
        ring1b.frequency.setValueAtTime(1400, cycleStart);
        ring1b.type = 'sine';

        // Main gain envelope
        gain1.gain.setValueAtTime(0, cycleStart);
        gain1.gain.linearRampToValueAtTime(normalizedVolume, cycleStart + 0.015);
        gain1.gain.setValueAtTime(normalizedVolume, cycleStart + burstDuration - 0.03);
        gain1.gain.linearRampToValueAtTime(0, cycleStart + burstDuration);
        // Harmonic gain (slightly softer)
        gain1b.gain.setValueAtTime(0, cycleStart);
        gain1b.gain.linearRampToValueAtTime(normalizedVolume * 0.4, cycleStart + 0.015);
        gain1b.gain.setValueAtTime(normalizedVolume * 0.4, cycleStart + burstDuration - 0.03);
        gain1b.gain.linearRampToValueAtTime(0, cycleStart + burstDuration);

        ring1.start(cycleStart);
        ring1.stop(cycleStart + burstDuration);
        ring1b.start(cycleStart);
        ring1b.stop(cycleStart + burstDuration);
        this.alarmNodes.push(ring1, ring1b);

        // --- Second ring burst (slightly lower pitch for "ring-ring" effect) ---
        const burst2Start = cycleStart + burstDuration + gapBetweenBursts;
        const ring2 = audioContext.createOscillator();
        const gain2 = audioContext.createGain();
        const ring2b = audioContext.createOscillator();
        const gain2b = audioContext.createGain();

        ring2.connect(gain2);
        gain2.connect(audioContext.destination);
        ring2b.connect(gain2b);
        gain2b.connect(audioContext.destination);

        // Slightly different frequencies for variety
        ring2.frequency.setValueAtTime(850, burst2Start);
        ring2.type = 'square';
        ring2b.frequency.setValueAtTime(1350, burst2Start);
        ring2b.type = 'sine';

        gain2.gain.setValueAtTime(0, burst2Start);
        gain2.gain.linearRampToValueAtTime(normalizedVolume, burst2Start + 0.015);
        gain2.gain.setValueAtTime(normalizedVolume, burst2Start + burstDuration - 0.03);
        gain2.gain.linearRampToValueAtTime(0, burst2Start + burstDuration);
        gain2b.gain.setValueAtTime(0, burst2Start);
        gain2b.gain.linearRampToValueAtTime(normalizedVolume * 0.4, burst2Start + 0.015);
        gain2b.gain.setValueAtTime(normalizedVolume * 0.4, burst2Start + burstDuration - 0.03);
        gain2b.gain.linearRampToValueAtTime(0, burst2Start + burstDuration);

        ring2.start(burst2Start);
        ring2.stop(burst2Start + burstDuration);
        ring2b.start(burst2Start);
        ring2b.stop(burst2Start + burstDuration);
        this.alarmNodes.push(ring2, ring2b);
      }

      // Total duration: 4 cycles × ~1.3s = ~5.2s + final attention bell
      const totalRingDuration = ringCycles * cycleDuration;

      // === Final attention bell: 3 rapid high-pitched dings ===
      const dingStart = startTime + totalRingDuration;
      const dingFreqs = [1200, 1400, 1600]; // Ascending dings
      for (let i = 0; i < 3; i++) {
        const dOsc = audioContext.createOscillator();
        const dGain = audioContext.createGain();
        dOsc.connect(dGain);
        dGain.connect(audioContext.destination);
        dOsc.frequency.setValueAtTime(dingFreqs[i], dingStart + i * 0.2);
        dOsc.type = 'sine';
        dGain.gain.setValueAtTime(0, dingStart + i * 0.2);
        dGain.gain.linearRampToValueAtTime(normalizedVolume * 0.8, dingStart + i * 0.2 + 0.01);
        dGain.gain.exponentialRampToValueAtTime(0.01, dingStart + i * 0.2 + 0.25);
        dOsc.start(dingStart + i * 0.2);
        dOsc.stop(dingStart + i * 0.2 + 0.25);
        this.alarmNodes.push(dOsc);
      }

      const totalDuration = totalRingDuration + 0.8; // ~6s total
      await new Promise(resolve => setTimeout(resolve, totalDuration * 1000 + 200));
      this.isAlarmPlaying = false;
      this.alarmNodes = [];
      console.log('✅ Option D: Urgent Order Alarm played');
    } catch (error) {
      this.isAlarmPlaying = false;
      this.alarmNodes = [];
      console.error('❌ Option D failed:', error);
      throw error;
    }
  }

  // Stop the alarm if it's currently playing
  public stopAlarm(): void {
    if (this.isAlarmPlaying) {
      for (const node of this.alarmNodes) {
        try { node.stop(); } catch { /* already stopped */ }
      }
      this.alarmNodes = [];
      this.isAlarmPlaying = false;
      console.log('🔇 Alarm stopped');
    }
  }

  public async playOrderReceivedSound(): Promise<void> {
    console.log(`🔔 Playing order received sound (Option ${this.soundOption})`);
    
    if (!this.isEnabled) {
      console.log('🔇 Sound notifications are disabled');
      return;
    }

    this.triggerVibration([
      300, 100, 300, 200,
      300, 100, 300, 200,
      300, 100, 300, 200,
      400, 100, 400
    ]);

    try {
      switch (this.soundOption) {
        case 'A':
          await this.playOptionA_MultiToneChime();
          break;
        case 'B':
          await this.playOptionB_ClassicNotification();
          break;
        case 'C':
          await this.playOptionC_DoubleBeepPattern();
          break;
        case 'D':
          await this.playOptionD_UrgentOrderAlarm();
          break;
        default:
          await this.playOptionD_UrgentOrderAlarm();
      }
    } catch (error) {
      console.warn('⚠️ Web Audio failed for order sound, trying fallback:', error);
      await this.playFallbackAudio();
    }
  }

  public async playOrderStatusUpdateSound(): Promise<void> {
    console.log('🔔 Playing order status update sound');
    await this.playNotificationSound();
  }

  public testSound(): Promise<void> {
    console.log('🧪 Testing sound notification');
    return this.playNotificationSound();
  }

  // Test methods for the three options
  public async testOptionA(): Promise<void> {
    console.log('🧪 Testing Option A: Multi-tone chime');
    await this.playOptionA_MultiToneChime();
  }

  public async testOptionB(): Promise<void> {
    console.log('🧪 Testing Option B: Classic notification');
    await this.playOptionB_ClassicNotification();
  }

public async testOptionC(): Promise<void> {
    console.log('🧪 Testing Option C: Double beep pattern');
    await this.playOptionC_DoubleBeepPattern();
  }

  public async testOptionD(): Promise<void> {
    console.log('🧪 Testing Option D: Urgent Order Alarm');
    await this.playOptionD_UrgentOrderAlarm();
  }

public destroy(): void {
    this.stopAlarm();
    if (this.keepAliveInterval) {
      clearInterval(this.keepAliveInterval);
      this.keepAliveInterval = null;
    }
    if (this.audioContext) {
      this.audioContext.close();
      this.audioContext = null;
    }
    console.log('🔊 Sound service destroyed');
  }
}

// Create a singleton instance
export const soundNotificationService = new SoundNotificationService();

// Export the class for testing purposes
export default SoundNotificationService;
