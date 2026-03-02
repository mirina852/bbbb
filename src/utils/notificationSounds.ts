export class NotificationSounds {
  private audioContext: AudioContext | null = null;
  private isInitialized = false;

  // Initialize audio context on first user interaction
  private initializeOnUserInteraction() {
    if (this.isInitialized) return;
    
    const handleUserInteraction = () => {
      if (!this.isInitialized) {
        this.getAudioContext();
        this.isInitialized = true;
        document.removeEventListener('click', handleUserInteraction);
        document.removeEventListener('keydown', handleUserInteraction);
        document.removeEventListener('touchstart', handleUserInteraction);
      }
    };

    document.addEventListener('click', handleUserInteraction, { once: true });
    document.addEventListener('keydown', handleUserInteraction, { once: true });
    document.addEventListener('touchstart', handleUserInteraction, { once: true });
  }

  private getAudioContext() {
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    }
    return this.audioContext;
  }

  private createTone(frequency: number, duration: number, volume: number) {
    const context = this.getAudioContext();
    const oscillator = context.createOscillator();
    const gainNode = context.createGain();

    oscillator.connect(gainNode);
    gainNode.connect(context.destination);

    oscillator.frequency.setValueAtTime(frequency, context.currentTime);
    oscillator.type = 'sine';

    gainNode.gain.setValueAtTime(0, context.currentTime);
    gainNode.gain.linearRampToValueAtTime(volume, context.currentTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.001, context.currentTime + duration);

    oscillator.start(context.currentTime);
    oscillator.stop(context.currentTime + duration);

    return oscillator;
  }

  private getSoundDuration(type: string): number {
    const durations: { [key: string]: number } = {
      // Sons Clássicos
      'default': 200,
      'bell': 400,
      'chime': 500,
      'ring': 600,
      'vintage': 700,
      
      // Sons Modernos
      'digital': 300,
      'ping': 150,
      'pop': 100,
      'beep': 200,
      'laser': 400,
      
      // Sons Suaves
      'soft': 500,
      'gentle': 600,
      'whisper': 400,
      'breeze': 700,
      
      // Sons de Alerta
      'alert': 300,
      'urgent': 400,
      'alarm': 500,
      'siren': 800,
      
      // Sons Divertidos
      'happy': 600,
      'coin': 300,
      'success': 500,
      'magic': 700,
      'fanfare': 900,
      
      // Sons de Cozinha
      'kitchen': 400,
      'ding': 200,
      'order': 500,
      'delivery': 600,
      
      // Sons Naturais
      'birds': 800,
      'water': 900,
      'wind': 700,
      
      // Sons Tecnológicos
      'robot': 500,
      'space': 800,
      'futuristic': 700,
      'notification': 300
    };
    
    return durations[type] || 200;
  }

  async playSound(type: string, volume: number = 0.3, repeatCount: number = 1) {
    try {
      // Initialize on first call to setup user interaction listeners
      this.initializeOnUserInteraction();
      
      // Resume audio context if suspended (required for some browsers)
      const context = this.getAudioContext();
      if (context.state === 'suspended') {
        await context.resume();
      }

      // Função para reproduzir um único som
      const playOnce = () => {
        switch (type) {
          // SONS CLÁSSICOS
          case 'default':
            this.createTone(800, 0.2, volume);
            break;
            
          case 'bell':
            this.createTone(800, 0.1, volume);
            setTimeout(() => this.createTone(600, 0.1, volume * 0.7), 100);
            setTimeout(() => this.createTone(400, 0.2, volume * 0.5), 200);
            break;
            
          case 'chime':
            this.createTone(523, 0.15, volume);
            setTimeout(() => this.createTone(659, 0.15, volume), 150);
            setTimeout(() => this.createTone(784, 0.2, volume), 300);
            break;
            
          case 'ring':
            this.createTone(440, 0.2, volume);
            setTimeout(() => this.createTone(440, 0.2, volume), 250);
            setTimeout(() => this.createTone(440, 0.2, volume), 500);
            break;
            
          case 'vintage':
            this.createTone(300, 0.3, volume);
            setTimeout(() => this.createTone(250, 0.4, volume * 0.8), 300);
            break;
            
          // SONS MODERNOS
          case 'digital':
            this.createTone(1200, 0.1, volume);
            setTimeout(() => this.createTone(1400, 0.1, volume), 100);
            setTimeout(() => this.createTone(1600, 0.1, volume), 200);
            break;
            
          case 'ping':
            this.createTone(1000, 0.1, volume);
            setTimeout(() => this.createTone(800, 0.05, volume * 0.5), 100);
            break;
            
          case 'pop':
            this.createTone(1500, 0.05, volume);
            setTimeout(() => this.createTone(1200, 0.05, volume * 0.5), 50);
            break;
            
          case 'beep':
            this.createTone(900, 0.15, volume);
            setTimeout(() => this.createTone(900, 0.05, volume), 200);
            break;
            
          case 'laser':
            this.createTone(2000, 0.1, volume);
            setTimeout(() => this.createTone(1500, 0.1, volume), 100);
            setTimeout(() => this.createTone(1000, 0.1, volume), 200);
            setTimeout(() => this.createTone(500, 0.1, volume), 300);
            break;
            
          // SONS SUAVES
          case 'soft':
            this.createTone(400, 0.3, volume * 0.6);
            setTimeout(() => this.createTone(500, 0.2, volume * 0.5), 300);
            break;
            
          case 'gentle':
            this.createTone(350, 0.4, volume * 0.5);
            setTimeout(() => this.createTone(400, 0.2, volume * 0.4), 400);
            break;
            
          case 'whisper':
            this.createTone(300, 0.3, volume * 0.4);
            setTimeout(() => this.createTone(320, 0.1, volume * 0.3), 300);
            break;
            
          case 'breeze':
            this.createTone(250, 0.5, volume * 0.5);
            setTimeout(() => this.createTone(280, 0.2, volume * 0.4), 500);
            break;
            
          // SONS DE ALERTA
          case 'alert':
            this.createTone(1000, 0.1, volume);
            setTimeout(() => this.createTone(1000, 0.1, volume), 150);
            setTimeout(() => this.createTone(1000, 0.1, volume), 300);
            break;
            
          case 'urgent':
            this.createTone(1200, 0.1, volume);
            setTimeout(() => this.createTone(1400, 0.1, volume), 100);
            setTimeout(() => this.createTone(1200, 0.1, volume), 200);
            setTimeout(() => this.createTone(1400, 0.1, volume), 300);
            break;
            
          case 'alarm':
            this.createTone(1500, 0.15, volume);
            setTimeout(() => this.createTone(1300, 0.15, volume), 150);
            setTimeout(() => this.createTone(1500, 0.15, volume), 300);
            break;
            
          case 'siren':
            this.createTone(800, 0.2, volume);
            setTimeout(() => this.createTone(1200, 0.2, volume), 200);
            setTimeout(() => this.createTone(800, 0.2, volume), 400);
            setTimeout(() => this.createTone(1200, 0.2, volume), 600);
            break;
            
          // SONS DIVERTIDOS
          case 'happy':
            this.createTone(523, 0.1, volume);
            setTimeout(() => this.createTone(659, 0.1, volume), 100);
            setTimeout(() => this.createTone(784, 0.1, volume), 200);
            setTimeout(() => this.createTone(1047, 0.2, volume), 300);
            break;
            
          case 'coin':
            this.createTone(1000, 0.05, volume);
            setTimeout(() => this.createTone(1200, 0.1, volume), 50);
            setTimeout(() => this.createTone(1500, 0.15, volume), 150);
            break;
            
          case 'success':
            this.createTone(600, 0.1, volume);
            setTimeout(() => this.createTone(800, 0.1, volume), 100);
            setTimeout(() => this.createTone(1000, 0.2, volume), 200);
            setTimeout(() => this.createTone(1200, 0.1, volume), 400);
            break;
            
          case 'magic':
            this.createTone(800, 0.1, volume);
            setTimeout(() => this.createTone(1200, 0.1, volume), 100);
            setTimeout(() => this.createTone(1600, 0.1, volume), 200);
            setTimeout(() => this.createTone(2000, 0.2, volume), 300);
            setTimeout(() => this.createTone(2400, 0.2, volume * 0.5), 500);
            break;
            
          case 'fanfare':
            this.createTone(523, 0.15, volume);
            setTimeout(() => this.createTone(659, 0.15, volume), 150);
            setTimeout(() => this.createTone(784, 0.15, volume), 300);
            setTimeout(() => this.createTone(1047, 0.2, volume), 450);
            setTimeout(() => this.createTone(1047, 0.3, volume), 650);
            break;
            
          // SONS DE COZINHA/RESTAURANTE
          case 'kitchen':
            this.createTone(700, 0.1, volume);
            setTimeout(() => this.createTone(900, 0.1, volume), 100);
            setTimeout(() => this.createTone(700, 0.1, volume), 200);
            setTimeout(() => this.createTone(900, 0.1, volume), 300);
            break;
            
          case 'ding':
            this.createTone(1500, 0.1, volume);
            setTimeout(() => this.createTone(1200, 0.1, volume * 0.5), 100);
            break;
            
          case 'order':
            this.createTone(800, 0.15, volume);
            setTimeout(() => this.createTone(1000, 0.15, volume), 150);
            setTimeout(() => this.createTone(800, 0.2, volume), 300);
            break;
            
          case 'delivery':
            this.createTone(600, 0.2, volume);
            setTimeout(() => this.createTone(800, 0.2, volume), 200);
            setTimeout(() => this.createTone(600, 0.2, volume), 400);
            break;
            
          // SONS NATURAIS
          case 'birds':
            this.createTone(2000, 0.1, volume * 0.6);
            setTimeout(() => this.createTone(2500, 0.1, volume * 0.5), 100);
            setTimeout(() => this.createTone(2200, 0.1, volume * 0.6), 200);
            setTimeout(() => this.createTone(2800, 0.2, volume * 0.5), 300);
            setTimeout(() => this.createTone(2400, 0.2, volume * 0.4), 500);
            break;
            
          case 'water':
            this.createTone(200, 0.3, volume * 0.4);
            setTimeout(() => this.createTone(250, 0.3, volume * 0.4), 300);
            setTimeout(() => this.createTone(220, 0.3, volume * 0.4), 600);
            break;
            
          case 'wind':
            this.createTone(150, 0.5, volume * 0.3);
            setTimeout(() => this.createTone(180, 0.2, volume * 0.3), 500);
            break;
            
          // SONS TECNOLÓGICOS
          case 'robot':
            this.createTone(300, 0.1, volume);
            setTimeout(() => this.createTone(400, 0.1, volume), 100);
            setTimeout(() => this.createTone(300, 0.1, volume), 200);
            setTimeout(() => this.createTone(500, 0.2, volume), 300);
            break;
            
          case 'space':
            this.createTone(100, 0.3, volume * 0.7);
            setTimeout(() => this.createTone(200, 0.2, volume * 0.6), 300);
            setTimeout(() => this.createTone(300, 0.3, volume * 0.5), 500);
            break;
            
          case 'futuristic':
            this.createTone(1800, 0.1, volume);
            setTimeout(() => this.createTone(1600, 0.1, volume), 100);
            setTimeout(() => this.createTone(1400, 0.1, volume), 200);
            setTimeout(() => this.createTone(1200, 0.1, volume), 300);
            setTimeout(() => this.createTone(1000, 0.2, volume), 400);
            break;
            
          case 'notification':
            this.createTone(1100, 0.1, volume);
            setTimeout(() => this.createTone(1300, 0.1, volume), 100);
            setTimeout(() => this.createTone(1100, 0.1, volume), 200);
            break;
            
          default:
            this.createTone(800, 0.2, volume);
        }
      };

      // Reproduzir o som com repetições
      for (let i = 0; i < repeatCount; i++) {
        if (i === 0) {
          playOnce();
        } else {
          // Delay entre repetições (varia por tipo de som)
          const delay = this.getSoundDuration(type) + 300; // 300ms entre repetições
          setTimeout(() => playOnce(), delay * i);
        }
      }
    } catch (error) {
      console.warn('Erro ao reproduzir som de notificação:', error);
      // Fallback para notification API se disponível
      this.fallbackNotificationSound();
    }
  }

  private fallbackNotificationSound() {
    try {
      // Use the browser's notification sound if available
      if ('Notification' in window && Notification.permission === 'granted') {
        const notification = new Notification('', {
          tag: 'sound-only',
          silent: false,
          body: ' ',
        });
        
        // Close immediately since we only want the sound
        setTimeout(() => notification.close(), 1);
      }
    } catch (error) {
      console.warn('Fallback notification sound failed:', error);
    }
  }
}

// Create a singleton instance
export const notificationSounds = new NotificationSounds();