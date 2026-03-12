import { useEffect, useState } from 'react';
import { getBezierPath } from '@xyflow/react';

export default function FlowAnimation({ 
  sourceX, 
  sourceY, 
  targetX, 
  targetY, 
  sourcePosition, 
  targetPosition,
  amount,
  duration = 2000 
}) {
  const [progress, setProgress] = useState(0);
  const [isAnimating, setIsAnimating] = useState(true);

  useEffect(() => {
    if (!isAnimating) return;

    const startTime = Date.now();
    
    const animate = () => {
      const elapsed = Date.now() - startTime;
      const newProgress = Math.min(elapsed / duration, 1);
      
      setProgress(newProgress);
      
      if (newProgress < 1) {
        requestAnimationFrame(animate);
      } else {
        setIsAnimating(false);
      }
    };
    
    requestAnimationFrame(animate);
  }, [duration, isAnimating]);

  // Calculate the path
  const [edgePath] = getBezierPath({
    sourceX,
    sourceY,
    sourcePosition,
    targetX,
    targetY,
    targetPosition,
  });

  // Get point along path at current progress
  const getPointAtProgress = (progress) => {
    // Simple linear interpolation for demo
    // For curved paths, you'd need to calculate along the bezier curve
    const x = sourceX + (targetX - sourceX) * progress;
    const y = sourceY + (targetY - sourceY) * progress;
    return { x, y };
  };

  const point = getPointAtProgress(progress);

  if (!isAnimating && progress >= 1) return null;

  return (
    <g>
      {/* Animated circle */}
      <circle
        cx={point.x}
        cy={point.y}
        r={8}
        fill="#10b981"
        stroke="#fff"
        strokeWidth={2}
        opacity={1 - progress * 0.3}
      >
        <animate
          attributeName="r"
          values="8;12;8"
          dur="0.6s"
          repeatCount="indefinite"
        />
      </circle>
      
      {/* Amount label */}
      {amount && (
        <text
          x={point.x}
          y={point.y - 15}
          textAnchor="middle"
          fill="#10b981"
          fontSize="12"
          fontWeight="bold"
          opacity={1 - progress * 0.5}
        >
          ${amount}
        </text>
      )}
    </g>
  );
}
