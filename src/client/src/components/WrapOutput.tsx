import * as React from 'react';
import { connect, useSelector } from 'react-redux';

import { MATTStore } from '../redux/main';

interface OutputWrapProps {
  props: {[key: string]: any};
  Component: React.ComponentType;
}

const WrapOutput = (
  Component: React.ComponentType<any>, 
  outputHash: string
) => {

  const wrappedComponent:React.FC<OutputWrapProps> = (subProps) => {
      const outputValue = useSelector(
        (state:MATTStore) => state.outputs[outputHash]
      )

      return <Component {...subProps} value={outputValue}/>
    }

  return wrappedComponent
}

export default WrapOutput;
