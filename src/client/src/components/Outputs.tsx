import * as React from 'react';

import { Text } from 'office-ui-fabric-react/lib/Text';

import { ComponentSet } from './types';

interface TextOutputProps {
  monospace: boolean; 
  value: string;
}

const TextOutput: React.FC<TextOutputProps> = (props) => {
  return (
    <Text block>{props.value}</Text>
  );
};

const componentSet: ComponentSet = {
  TextOutput
}

export default componentSet;