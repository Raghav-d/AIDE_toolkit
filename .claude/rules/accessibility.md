# Accessibility Rules (WCAG 2.1 AA)

## Required in every component
- All interactive elements must have an accessible name
- Form inputs must have associated label (htmlFor or wrapping label)
- Error messages must use role="alert" or aria-live="polite"
- Loading states must use aria-busy="true" on the container
- Focus must not be lost after async actions
- No tabIndex > 0

## Omni components
- Use Omni components for interactive elements — they handle a11y internally
- When wrapping Omni, preserve all aria props
- Do not override Omni's built-in focus management

## Testing requirement
Every generated test file must include at least one axe check:
```ts
import { axe } from 'jest-axe'
it('has no axe violations', async () => {
  const { container } = render(<Component />)
  expect(await axe(container)).toHaveNoViolations()
})
```
