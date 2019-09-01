import * as React from 'react';

import { ComponentSet } from './types';

import { Toggle } from 'office-ui-fabric-react/lib/Toggle';
import { Slider } from 'office-ui-fabric-react/lib/Slider';
import { ChoiceGroup } from 'office-ui-fabric-react/lib/ChoiceGroup';

interface ChoiceGroupProps {
  __hash: string;
  label: string;
  options: { [key: string]: string };
  defaultSelectedKey: string;
  value: string;
  onChange: (ev?: React.FormEvent) => any;
}

const MATTChoiceGroup: React.FC<ChoiceGroupProps> = (props) => {
  const options = Object.entries(props.options)
                        .map(([key, text]) => ({key, text})); //prettier-ignore

  return (
    <ChoiceGroup
      label={props.label}
      options={options}
      defaultSelectedKey={props.defaultSelectedKey}
      value={props.value}
      onChange={props.onChange}
    />
  );
};

interface SplitViewProps {
  widths: number[]
}

const MATTSplitView: React.FC<SplitViewProps> = (props) => {
  let index = -1;
  return <div style={{display: "flex"}}>
    {props.children && React.Children.map(props.children, (child, index) => {
      index ++;
      return <div style={{flexGrow: props.widths[index] || 0}}>{child}</div>
    })}
  </div>
}

interface StackViewProps {

}

const MATTStackView: React.FC<StackViewProps> = (props) => {
  return <div>
    {props.children && React.Children.map(props.children, (child) => {
      return <div>{child}</div>
    })}
  </div>
}

const componentSet: ComponentSet = {
  Toggle: Toggle,
  ChoiceGroup: MATTChoiceGroup,
  Slider: Slider,
  StackView: MATTStackView,
  SplitView: MATTSplitView
};

export default componentSet;
