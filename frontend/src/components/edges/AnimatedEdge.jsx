import { BaseEdge, EdgeLabelRenderer, getBezierPath } from '@xyflow/react';
import { useState, useEffect } from 'react';
import FlowAnimation from '../FlowAnimation';

export default function AnimatedEdge({
  id,
  sourceX,
  sourceY,
  targetX,
  targetY,
  sourcePosition,
  targetPosition,
  style = {},
  markerEnd,
  data,
}) {
  const [edgePath, labelX, labelY] = getBezierPath({
    sourceX,
    sourceY,
    sourcePosition,
    targetX,
    targetY,
    targetPosition,
  });

  const [animations, setAnimations] = useState([]);

  const triggerFlow = (amount) => {
    const newAnimation = {
      id: Date.now(),
      amount,
      sourceX,
      sourceY,
      targetX,
      targetY,
      sourcePosition,
      targetPosition,
    };
    
    setAnimations(prev => [...prev, newAnimation]);
    
    // Remove animation after it completes
    setTimeout(() => {
      setAnimations(prev => prev.filter(a => a.id !== newAnimation.id));
    }, 2000);
  };

  // Register trigger function with parent
  useEffect(() => {
    if (data?.registerTrigger) {
      data.registerTrigger(id, triggerFlow);
    }
    return () => {
      if (data?.unregisterTrigger) {
        data.unregisterTrigger(id);
      }
    };
  }, [id, data]);

  return (
    <>
      <BaseEdge path={edgePath} markerEnd={markerEnd} style={style} />
      
      {/* Render active animations */}
      {animations.map(anim => (
        <FlowAnimation
          key={anim.id}
          sourceX={anim.sourceX}
          sourceY={anim.sourceY}
          targetX={anim.targetX}
          targetY={anim.targetY}
          sourcePosition={anim.sourcePosition}
          targetPosition={anim.targetPosition}
          amount={anim.amount}
          duration={2000}
        />
      ))}

      <EdgeLabelRenderer>
        <div
          style={{
            position: 'absolute',
            transform: `translate(-50%, -50%) translate(${labelX}px,${labelY}px)`,
            fontSize: 12,
            pointerEvents: 'all',
          }}
          className="nodrag nopan"
        >
          <button
            onClick={() => triggerFlow(100)}
            className="px-2 py-1 bg-green-500 text-white rounded text-xs hover:bg-green-600"
          >
            💸 Flow $100
          </button>
        </div>
      </EdgeLabelRenderer>
    </>
  );
}
