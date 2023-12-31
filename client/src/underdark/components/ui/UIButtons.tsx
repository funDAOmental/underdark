
type ActionButtonProps = {
  label: string
  disabled?: boolean
  large?: boolean
  fill?: boolean
  dimmed?: boolean
  onClick: () => void
};

const ActionButton = ({
  label,
  disabled = false,
  large = false,
  fill = false,
  dimmed = false,
  onClick,
}: ActionButtonProps) => {
  let classNames = ['FillParent']
  classNames.push((disabled || dimmed) ? 'Locked' : 'Unlocked')
  if (large) classNames.push('LargeButton')
  if (fill) classNames.push('FillParent')
  const _button = <button className={classNames.join(' ')} disabled={disabled} onClick={() => onClick()}>{label}</button>
  if (large) {
    return <h3>{_button}</h3>
  }
  return <h4>{_button}</h4>
}


// const PrevButton = (props) => (PrevNextButton({ ...props, direction: -1 }))
// const NextButton = (props) => (PrevNextButton({ ...props, direction: 1 }))

type PrevNextButtonProps = {
  direction: number
  label?: string
  disabled?: boolean
  onClick: () => void
};

const PrevNextButton = ({
  label = null,
  disabled = false,
  direction,
  onClick,
}: PrevNextButtonProps) => {
  const _label = label ?? (direction < 0 ? '<' : '>')
  const _className = disabled ? 'Locked' : 'Unlocked'
  return <button className={`DirectionButton ${_className}`} disabled={disabled} onClick={() => onClick()}>{_label}</button>
}


export {
  ActionButton,
  // NextButton,
  // PrevButton,
  PrevNextButton,
}