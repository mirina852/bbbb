import React, { useState, useEffect } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface BackgroundCarouselProps {
  images: string[];
  logoUrl?: string | null;
  logoTop?: number;
  logoLeft?: number;
}

const BackgroundCarousel: React.FC<BackgroundCarouselProps> = ({
  images,
  logoUrl,
  logoTop = 105,
  logoLeft = 20
}) => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const imagesToShow = 2; // Mostra 2 imagens por vez

  // Auto-slide a cada 4 segundos
  useEffect(() => {
    if (images.length <= imagesToShow) return;

    const interval = setInterval(() => {
      setCurrentIndex((prevIndex) => {
        const maxIndex = images.length - imagesToShow;
        return prevIndex >= maxIndex ? 0 : prevIndex + 1;
      });
    }, 4000);

    return () => clearInterval(interval);
  }, [images.length]);

  const goToNext = () => {
    const maxIndex = images.length - imagesToShow;
    setCurrentIndex((prevIndex) => 
      prevIndex >= maxIndex ? 0 : prevIndex + 1
    );
  };

  const goToPrevious = () => {
    const maxIndex = images.length - imagesToShow;
    setCurrentIndex((prevIndex) => 
      prevIndex <= 0 ? maxIndex : prevIndex - 1
    );
  };

  if (images.length === 0) {
    return (
      <div className="relative mb-12 overflow-visible">
        <div className="h-40 md:h-48 bg-gray-200 rounded-lg flex items-center justify-center">
          <span className="text-gray-500">Nenhuma imagem configurada</span>
        </div>
      </div>
    );
  }

  // Se há apenas 1 imagem, mostra sem carrossel
  if (images.length === 1) {
    return (
      <div className="relative mb-12 overflow-visible">
        <div
          className="h-40 md:h-48 bg-cover bg-center bg-no-repeat rounded-lg relative"
          style={{
            backgroundImage: `url(${images[0]})`,
          }}
        >
          {logoUrl && (
            <img
              src={logoUrl}
              alt="Logo"
              className="absolute"
              style={{
                top: `${logoTop}px`,
                left: `${logoLeft}px`,
                maxHeight: '90px',
                borderRadius: '8px',
                objectFit: 'cover',
                boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
              }}
            />
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="relative mb-12 overflow-hidden">
      <div className="relative h-40 md:h-48 rounded-lg overflow-hidden">
        {/* Container das imagens */}
        <div 
          className="flex transition-transform duration-500 ease-in-out h-full"
          style={{
            transform: `translateX(-${currentIndex * (100 / imagesToShow)}%)`,
            width: `${(images.length / imagesToShow) * 100}%`
          }}
        >
          {images.map((image, index) => (
            <div
              key={index}
              className="relative flex-shrink-0 bg-cover bg-center bg-no-repeat"
              style={{
                backgroundImage: `url(${image})`,
                width: `${100 / images.length}%`,
              }}
            />
          ))}
        </div>

        {/* Logo sobreposto */}
        {logoUrl && (
          <img
            src={logoUrl}
            alt="Logo"
            className="absolute z-10"
            style={{
              top: `${logoTop}px`,
              left: `${logoLeft}px`,
              maxHeight: '90px',
              borderRadius: '8px',
              objectFit: 'cover',
              boxShadow: '0 4px 8px rgba(0,0,0,0.2)',
            }}
          />
        )}

        {/* Setas de navegação */}
        {images.length > imagesToShow && (
          <>
            <button
              onClick={goToPrevious}
              className="absolute left-2 top-1/2 -translate-y-1/2 bg-black/30 hover:bg-black/50 text-white p-2 rounded-full transition-colors z-10"
              aria-label="Imagem anterior"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            <button
              onClick={goToNext}
              className="absolute right-2 top-1/2 -translate-y-1/2 bg-black/30 hover:bg-black/50 text-white p-2 rounded-full transition-colors z-10"
              aria-label="Próxima imagem"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </>
        )}

        {/* Indicadores de página */}
        {images.length > imagesToShow && (
          <div className="absolute bottom-3 left-1/2 -translate-x-1/2 flex gap-2 z-10">
            {Array.from({ length: Math.ceil(images.length - imagesToShow + 1) }, (_, index) => (
              <button
                key={index}
                onClick={() => setCurrentIndex(index)}
                className={`w-2 h-2 rounded-full transition-colors ${
                  currentIndex === index ? 'bg-white' : 'bg-white/50'
                }`}
                aria-label={`Ir para slide ${index + 1}`}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default BackgroundCarousel;